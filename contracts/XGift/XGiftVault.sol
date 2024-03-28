//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./XGiftBase.sol";

contract XGiftVault is XGiftBase {
    constructor(IbcDispatcher _dispatcher) XGiftBase(_dispatcher) {}

    function deposit(
        bytes32 channelId,
        uint64 timeoutSeconds
    ) external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        // Save ibc packet
        bytes32 packetId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp)
        );
        IbcPacketBalance memory payload = IbcPacketBalance({
            id: packetId,
            amount: msg.value,
            sender: msg.sender,
            ibcStatus: IbcPacketStatus.UNSENT
        });
        depositPackets[packetId] = payload;
        bytes memory data = abi.encode(payload);
        emit Deposit(msg.sender, msg.value, packetId);
        // Send packet
        sendPacket(
            channelId,
            timeoutSeconds,
            abi.encode(IbcPacketType.DEPOSIT, data)
        );
    }

    function withdraw(uint _amount) external {
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(balancesOf[msg.sender] >= _amount, "Insufficient balance");

        balancesOf[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
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
        (
            IbcPacketType packetType,
            bytes memory data
        ) = abi.decode(packet.data, (IbcPacketType, bytes));

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
        (
            IbcPacketType packetType,
            bytes memory data
        ) = abi.decode(ack.data, (IbcPacketType, bytes));

        if (packetType == IbcPacketType.DEPOSIT) {
            IbcPacketBalance memory balance = abi.decode(data, (IbcPacketBalance));
            balancesOf[balance.sender] += balance.amount;
            depositPackets[balance.id].ibcStatus = IbcPacketStatus.ACKED;
            emit AckDeposit(balance.sender, balance.amount, balance.id);
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
