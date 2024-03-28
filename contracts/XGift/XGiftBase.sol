//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "../base/CustomChanIbcApp.sol";

contract XGiftBase is CustomChanIbcApp {
    enum IbcPacketStatus {
        UNSENT,
        SENT,
        ACKED,
        TIMEOUT
    }

    enum IbcPacketType {
        CREATE_GIFT,
        GIFT,
        CLAIM
    }

    struct Gift {
        bytes32 id;
        address sender;
        address receiver;
        uint256 amount;
        IbcPacketStatus ibcStatus;
        bool isClaimed;
        bool isCancelled;
    }

    struct IbcPacketCreateGift {
        bytes32 id;
        address sender;
        address receiver;
        uint amount;
        IbcPacketStatus ibcStatus;
    }

    mapping(bytes32 => IbcPacketCreateGift) public createGiftPackets;

    mapping(bytes32 => Gift) public gifts;
    mapping(address => bytes32[]) public giftLinksOf;

    event ClaimGift(address indexed receiver, uint256 amount, bytes32 id);
    event AckClaimGift(address indexed receiver, uint256 amount, bytes32 id);
    event CreateGif(address indexed sender, uint256 amount, bytes32 id);
    event AckDeposit(address indexed sender, uint256 amount, bytes32 id);

    constructor(IbcDispatcher _dispatcher) CustomChanIbcApp(_dispatcher) {}

    function bytes32ToString(
        bytes32 _bytes32Value
    ) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32Value[i];
        }
        return string(bytesArray);
    }

    // ----------------------- IBC logic  -----------------------
    /**
     * @dev Sends a packet with the caller address over a specified channel.
     * @param channelId The ID of the channel (locally) to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */
    function sendPacket(
        bytes32 channelId,
        uint64 timeoutSeconds,
        bytes memory payload
    ) internal {
        // setting the timeout timestamp at 10h from now
        uint64 timeoutTimestamp = uint64(
            (block.timestamp + timeoutSeconds) * 1000000000
        );

        // calling the Dispatcher to send the packet
        dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }
}
