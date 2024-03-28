//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./XGiftBase.sol";

contract XGiftVault is XGiftBase {
    constructor(IbcDispatcher _dispatcher) XGiftBase(_dispatcher) {}

    function createGift(
        bytes32 channelId,
        uint64 timeoutSeconds,
        address _receiver
    ) external payable {
        require(msg.value > 0, "Gift amount must be greater than zero");
        require(
            _receiver != msg.sender,
            "Sender and receiver cannot be the same"
        );
        // Save ibc packet
        bytes32 packetId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp)
        );
        IbcPacketCreateGift memory payload = IbcPacketCreateGift({
            id: packetId,
            amount: msg.value,
            sender: msg.sender,
            receiver: _receiver,
            ibcStatus: IbcPacketStatus.UNSENT
        });
        createGiftPackets[packetId] = payload;
        bytes memory data = abi.encode(payload);
        emit CreateGif(msg.sender, msg.value, packetId);
        // Send packet
        sendPacket(
            channelId,
            timeoutSeconds,
            abi.encode(IbcPacketType.CREATE_GIFT, data)
        );
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

        if (packetType == IbcPacketType.CLAIM) {
            Gift memory gift = abi.decode(data, (Gift));
            emit ClaimGift(gift.receiver, gift.amount, gift.id);
            payable(gift.receiver).transfer(gift.amount);
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

        if (packetType == IbcPacketType.CREATE_GIFT) {
            IbcPacketCreateGift memory gift = abi.decode(
                data,
                (IbcPacketCreateGift)
            );
            createGiftPackets[gift.id].ibcStatus = IbcPacketStatus.ACKED;
            emit AckDeposit(gift.sender, gift.amount, gift.id);
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
