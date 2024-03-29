# PIT Phase 1 repo project: Cross-chain give GIFs


## Team Members


## Description

A and B are friends, A has used both Base and OP networks, while B only knows how to use the OP network. A wants to introduce B to use the Base network, so A has created a gif link for B to claim and receive eth on the Base network.

This application allows users to create gifs on the Base Sepolia network. Gif information will be sent to an XGif contract on the OP Sepolia network for users on the OP Sepolia network to claim gifs and receive eth gifts on the Base Sepolia network.

Features:

- Use Polymer x IBC as the cross-chain format.
- Committing to the ethos of application-specific chains/rollups, where gif creation functionality can be specialized on one chain, and gif claiming on another chain.

## Resources used

The repo uses the [ibc-app-solidity-template](https://github.com/open-ibc/ibc-app-solidity-template) as starting point and adds custom contracts XGiftVault and XGift that implement the custom logic.

It changes the send-packet.js script slightly to adjust to the custom logic.

The expected behaviour from the template should still work but nevertheless we quickly review the steps for the user to test the application...
Run `just --list` for a full overview of the just commands.

Additional resources used:
- Hardhat
- Blockscout
- Tenderly

## Steps to reproduce

After cloning the repo, install dependencies:

```sh
just install
```

And add your private key to the .env file (rename it from .env.example).

Then make sure that the config has the right contracts:
```sh
just set-contracts optimism XGift false && just set-contracts base XGiftVault false
```

> Note: The order matters here! Make sure to have the exact configuration

Check if the contracts compile:
```sh
just compile
```
### Deployment and creating channels (optional)

Then you can deploy the contract if you want to have a custom version, but you can use the provided contract addresses that are prefilled in the config. If using the default, you can skip to the step to send packets.

If you want to deploy your own, run:
```sh
just deploy optimism base
```
and create a channel:
```sh
just create-channel
```

### Create a gift

```bash
just create-gift-link base
```

### Check list gift by receiver address

```bash
just list-gift optimism
```

###  Claim gift

> Please pick gift id in list gifts and edit receiver address in file ``scripts/gift/claim-gif.js``

```bash
just claim-gift optimism
```


## Proof of testnet interaction

After following the steps above you should have interacted with the testnet. You can check this at the [IBC Explorer](https://explorer.ethdenver.testnet.polymer.zone/).

Here's the data of our application:

- XGiftValue (Base Sepolia) : 0x6101c78e408B1e63ac7a9519054c6564Da758467
- XGift (OP Sepolia): 0xdC828bf7a839Abef63A9bd4a436E8E432DEadea2
- Channel (OP Sepolia): channel-39944
- Channel (Base Sepolia): channel-39945

- Proof of Create Gift:
    - [SendTx](https://base-sepolia.blockscout.com/tx/0xaefc6889a7fa948b9ee6d613b7273cef97f30e57d65d8777f70df861d5e70579)
    - [RecvTx](https://optimism-sepolia.blockscout.com/tx/0x6b8914d75a2ecf6a7180c7bd9e767117cdfc59a111573dcbcbefaa9b057894a7)
    - [Ack](https://base-sepolia.blockscout.com/tx/0xffa582fc1b1b474a11f23846b490f43e47eed7913d77b862270e9bd12c1091a0)

- Proof of Claim Gift:
    - [SendTx](https://optimism-sepolia.blockscout.com/tx/0x97c637d215d06efc43ce207595ff554c0561f818985da369eca4673480865910)
    - [RecvTx](https://optimism-sepolia.blockscout.com/tx/0x6b8914d75a2ecf6a7180c7bd9e767117cdfc59a111573dcbcbefaa9b057894a7)
    - [Ack](https://base-sepolia.blockscout.com/tx/0xffa582fc1b1b474a11f23846b490f43e47eed7913d77b862270e9bd12c1091a0)

## Challenges Faced

- Debugging used to be tricky when the sendPacket on the contract was successfully submitted but there was an error further down the packet lifecycle.
What helped was to verify the contracts and use Tenderly for step-by-step debugging to see what the relayers submitted to the dispatcher etc.

## What we learned

How to make the first dApp using Polymer.

## Future improvements

Basic functionality was implemented, but the following things can be improved:

- More tests
- More input validation
- Add event listeners related to important IBC lifecycle steps

## Licence

[Apache 2.0](LICENSE)
