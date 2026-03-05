const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 BlockAI NFT Mint Contract Deployment");
  console.log("=====================================\n");
  
  const [deployer] = await ethers.getSigners();
  console.log(`📝 Deploying from: ${deployer.address}`);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Deployer balance: ${ethers.formatEther(balance)} ETH\n`);
  
  // Deployment parameters
  const name = "BlockAI NFT Collection";
  const symbol = "BAI";
  const whitelistPrice = ethers.parseEther("0.05"); // 0.05 ETH
  const publicPrice = ethers.parseEther("0.08"); // 0.08 ETH
  
  const currentTime = Math.floor(Date.now() / 1000);
  const whitelistStartTime = currentTime + 3600; // 1 hour from deployment
  const publicStartTime = currentTime + 7200; // 2 hours from deployment
  
  console.log("📋 Deployment Parameters:");
  console.log(`   Name: ${name}`);
  console.log(`   Symbol: ${symbol}`);
  console.log(`   Whitelist Price: ${ethers.formatEther(whitelistPrice)} ETH`);
  console.log(`   Public Price: ${ethers.formatEther(publicPrice)} ETH`);
  console.log(`   Whitelist Start: ${new Date(whitelistStartTime * 1000).toISOString()}`);
  console.log(`   Public Start: ${new Date(publicStartTime * 1000).toISOString()}\n`);
  
  // Deploy contract
  const NFTMint = await ethers.getContractFactory("NFTMint");
  const nftMint = await NFTMint.deploy(
    name,
    symbol,
    whitelistPrice,
    publicPrice,
    whitelistStartTime,
    publicStartTime
  );
  
  await nftMint.waitForDeployment();
  
  const contractAddress = await nftMint.getAddress();
  console.log("✅ Contract Deployed Successfully!");
  console.log(`📍 Contract Address: ${contractAddress}\n`);
  
  // Verify deployment
  console.log("🔍 Verifying Deployment...");
  console.log(`   Owner: ${await nftMint.owner()}`);
  console.log(`   Max Supply: 10000`);
  console.log(`   Max Per Wallet (Public): 5`);
  console.log(`   Max Per Wallet (Whitelist): 10`);
  console.log(`   Remaining Supply: ${await nftMint.remainingSupply()}\n`);
  
  // Network info
  const network = await ethers.provider.getNetwork();
  console.log("🌐 Network Information:");
  console.log(`   Chain ID: ${network.chainId}`);
  console.log(`   Network Name: ${hre.network.name}\n`);
  
  // Verification instructions
  console.log("📜 Contract Verification:");
  if (hre.network.name === "sepolia" || hre.network.name === "mainnet") {
    console.log(`   Run: npx hardhat verify --network ${hre.network.name} ${contractAddress} "${name}" "${symbol}" ${whitelistPrice} ${publicPrice} ${whitelistStartTime} ${publicStartTime}`);
  } else {
    console.log("   (Verification only available on public networks)");
  }
  
  console.log("\n=====================================");
  console.log("🎉 Deployment Complete!");
  console.log("=====================================");
  
  return {
    contractAddress,
    name,
    symbol,
    whitelistPrice,
    publicPrice,
    whitelistStartTime,
    publicStartTime
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
