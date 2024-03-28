//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./XGiftBase.sol";

contract XGift is XGiftBase {
    constructor(IbcDispatcher _dispatcher) XGiftBase(_dispatcher) {}

    function _createGift(
        address _receiver,
        uint256 _amount
    ) internal returns (bytes32) {
        require(_receiver != address(0), "Invalid receiver address");
        require(_amount > 0, "Invalid gift amount");

        bytes32 giftId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp)
        );

        Gift memory newGift = Gift({
            id: giftId,
            sender: msg.sender,
            receiver: _receiver,
            amount: _amount,
            ibcStatus: IbcPacketStatus.UNSENT,
            isClaimed: false,
            isCancelled: false
        });

        gifts[giftId] = newGift;
        giftLinksOf[_receiver].push(giftId);

        return giftId;
    }

    function claimGift(
        bytes32 channelId,
        uint64 timeoutSeconds,
        bytes32 _giftId
    ) external {
        Gift memory gift = gifts[_giftId];
        require(
            gift.receiver == msg.sender,
            "You are not the intended receiver of this gift"
        );
        require(
            gift.ibcStatus == IbcPacketStatus.UNSENT ||
                gift.ibcStatus == IbcPacketStatus.TIMEOUT,
            "Gift is not available for claiming"
        );
        require(!gift.isClaimed, "Gift has already been claimed");
        require(!gift.isCancelled, "Gift has been cancelled");
        gifts[_giftId].ibcStatus = IbcPacketStatus.SENT;
        emit ClaimGift(msg.sender, gift.amount, _giftId);
        bytes memory payload = abi.encode(gift);
        // Send packet
        sendPacket(
            channelId,
            timeoutSeconds,
            abi.encode(IbcPacketType.CLAIM, payload)
        );
    }

    function getGiftsByUser(
        address _user
    ) external view returns (bytes32[] memory) {
        return giftLinksOf[_user];
    }

    // ----------------------- IBC logic  -----------------------
    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param packet the IBC packet encoded by the source and relayed by the relayer.
     */
    function onRecvPacket(
        IbcPacket memory packet
    ) external override onlyIbcDispatcher returns (AckPacket memory ackPacket) {
        recvedPackets.push(packet);
        (IbcPacketType packetType, bytes memory data) = abi.decode(
            packet.data,
            (IbcPacketType, bytes)
        );

        if (packetType == IbcPacketType.CREATE_GIFT) {
            IbcPacketCreateGift memory createGift = abi.decode(
                data,
                (IbcPacketCreateGift)
            );
            _createGift(createGift.receiver, createGift.amount);
        } else {
            revert("Invalid packet type");
        }
        return AckPacket(true, packet.data);
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onAcknowledgementPacket(
        IbcPacket calldata,
        AckPacket calldata ack
    ) external override onlyIbcDispatcher {
        ackPackets.push(ack);
        (IbcPacketType packetType, bytes memory data) = abi.decode(
            ack.data,
            (IbcPacketType, bytes)
        );
        if (packetType == IbcPacketType.CLAIM) {
            Gift memory gift = abi.decode(data, (Gift));
            gifts[gift.id].isClaimed = true;
            gifts[gift.id].ibcStatus = IbcPacketStatus.ACKED;
            emit AckClaimGift(gift.receiver, gift.amount, gift.id);
        } else {
            revert("Invalid packet type");
        }
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param packet the IBC packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutPacket(
        IbcPacket calldata packet
    ) external override onlyIbcDispatcher {
        timeoutPackets.push(packet);
        // do logic
    }
}
