// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { getConfigPath } = require("../private/_helpers");
const { getIbcApp } = require("../private/_vibc-helpers.js");
const { setupIbcPacketEventListener } = require("../private/_events.js");

async function depositEth() {
  const accounts = await hre.ethers.getSigners();
  const config = require(getConfigPath());
  const sendConfig = config.sendPacket;

  const networkName = hre.network.name;
  // Get the contract type from the config and get the contract
  const ibcApp = await getIbcApp(networkName);

  // Do logic to prepare the packet
  const channelId = sendConfig[`${networkName}`]["channelId"];
  const channelIdBytes = hre.ethers.encodeBytes32String(channelId);
  const timeoutSeconds = sendConfig[`${networkName}`]["timeout"];
  const tx = await ibcApp
    .connect(accounts[1])
    .claimGift(channelIdBytes, timeoutSeconds, '0xbc63d901159cfd8772a8382b61b2d9f11340ca462bc4ed751488439ee9c41f4f');
  console.log("Tx hash: ", tx.hash);

  const balance = await ibcApp
    .connect(accounts[0])
    .balancesOf(accounts[0]);
  console.log("Balance: ", balance);
  console.log("Balance: ", hre.ethers.formatEther(balance));

  const gifts = await ibcApp
    .connect(accounts[0])
    .getGiftsByUser(accounts[0]);
  console.log("Balance: ", gifts);
}

async function main() {
  try {
    await setupIbcPacketEventListener();
    await depositEth();
  } catch (error) {
    console.error("❌ Error sending packet: ", error);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
