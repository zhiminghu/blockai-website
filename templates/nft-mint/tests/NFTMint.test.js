const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

describe("NFTMint", function () {
  let nftMint;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  
  const WHITELIST_PRICE = ethers.parseEther("0.05");
  const PUBLIC_PRICE = ethers.parseEther("0.08");
  
  // Time helpers
  const getCurrentTime = async () => {
    const block = await ethers.provider.getBlock("latest");
    return block.timestamp;
  };
  
  const increaseTime = async (seconds) => {
    await ethers.provider.send("evm_increaseTime", [seconds]);
    await ethers.provider.send("evm_mine");
  };
  
  // Create Merkle tree for whitelist
  const createMerkleTree = (addresses) => {
    const leaves = addresses.map(addr => keccak256(ethers.solidityPacked(["address"], [addr])));
    return new MerkleTree(leaves, keccak256, { sortPairs: true });
  };
  
  const getMerkleProof = (tree, address) => {
    const leaf = keccak256(ethers.solidityPacked(["address"], [address]));
    return tree.getHexProof(leaf);
  };
  
  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    
    const currentTime = await getCurrentTime();
    const whitelistStartTime = currentTime + 100;
    const publicStartTime = currentTime + 200;
    
    const NFTMint = await ethers.getContractFactory("NFTMint");
    nftMint = await NFTMint.deploy(
      "BlockAI NFT",
      "BAI",
      WHITELIST_PRICE,
      PUBLIC_PRICE,
      whitelistStartTime,
      publicStartTime
    );
    
    await nftMint.waitForDeployment();
  });
  
  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await nftMint.owner()).to.equal(owner.address);
    });
    
    it("Should set correct prices", async function () {
      expect(await nftMint.whitelistPrice()).to.equal(WHITELIST_PRICE);
      expect(await nftMint.publicPrice()).to.equal(PUBLIC_PRICE);
    });
    
    it("Should have correct max supply", async function () {
      expect(await nftMint.remainingSupply()).to.equal(10000);
    });
  });
  
  describe("Whitelist Minting", function () {
    it("Should allow whitelisted users to mint", async function () {
      const whitelistAddresses = [addr1.address, addr2.address];
      const tree = createMerkleTree(whitelistAddresses);
      const merkleRoot = tree.getRoot();
      
      await nftMint.setMerkleRoot(merkleRoot);
      
      // Fast forward to whitelist period
      await increaseTime(150);
      
      const proof = getMerkleProof(tree, addr1.address);
      
      await expect(
        nftMint.connect(addr1).mintWhitelist(1, proof, { value: WHITELIST_PRICE })
      ).to.not.be.reverted;
      
      expect(await nftMint.ownerOf(1)).to.equal(addr1.address);
      expect(await nftMint.mintedPerWallet(addr1.address)).to.equal(1);
    });
    
    it("Should reject invalid merkle proof", async function () {
      const fakeTree = createMerkleTree([addr3.address]);
      const fakeProof = getMerkleProof(fakeTree, addr1.address);
      
      await increaseTime(150);
      
      await expect(
        nftMint.connect(addr1).mintWhitelist(1, fakeProof, { value: WHITELIST_PRICE })
      ).to.be.reverted;
    });
    
    it("Should enforce max whitelist mint per wallet", async function () {
      const whitelistAddresses = [addr1.address];
      const tree = createMerkleTree(whitelistAddresses);
      await nftMint.setMerkleRoot(tree.getRoot());
      
      await increaseTime(150);
      
      const proof = getMerkleProof(tree, addr1.address);
      
      // Mint 10 (max)
      await nftMint.connect(addr1).mintWhitelist(10, proof, { value: WHITELIST_PRICE * 10n });
      
      // Try to mint 11th
      await expect(
        nftMint.connect(addr1).mintWhitelist(1, proof, { value: WHITELIST_PRICE })
      ).to.be.reverted;
    });
  });
  
  describe("Public Minting", function () {
    it("Should allow public minting after public sale starts", async function () {
      await increaseTime(250); // Past public start time
      
      await expect(
        nftMint.connect(addr1).mintPublic(1, { value: PUBLIC_PRICE })
      ).to.not.be.reverted;
      
      expect(await nftMint.ownerOf(1)).to.equal(addr1.address);
    });
    
    it("Should enforce max per wallet for public sale", async function () {
      await increaseTime(250);
      
      // Mint 5 (max)
      await nftMint.connect(addr1).mintPublic(5, { value: PUBLIC_PRICE * 5n });
      
      // Try to mint 6th
      await expect(
        nftMint.connect(addr1).mintPublic(1, { value: PUBLIC_PRICE })
      ).to.be.reverted;
    });
    
    it("Should reject insufficient payment", async function () {
      await increaseTime(250);
      
      await expect(
        nftMint.connect(addr1).mintPublic(1, { value: PUBLIC_PRICE - 1n })
      ).to.be.reverted;
    });
  });
  
  describe("Owner Functions", function () {
    it("Should allow owner to set prices", async function () {
      const newPrice = ethers.parseEther("0.1");
      
      await nftMint.setWhitelistPrice(newPrice);
      expect(await nftMint.whitelistPrice()).to.equal(newPrice);
      
      await nftMint.setPublicPrice(newPrice);
      expect(await nftMint.publicPrice()).to.equal(newPrice);
    });
    
    it("Should allow owner to set start times", async function () {
      const newTime = 1234567890n;
      
      await nftMint.setWhitelistStartTime(newTime);
      expect(await nftMint.whitelistStartTime()).to.equal(newTime);
      
      await nftMint.setPublicStartTime(newTime + 1000n);
      expect(await nftMint.publicStartTime()).to.equal(newTime + 1000n);
    });
    
    it("Should allow owner to withdraw funds", async function () {
      await increaseTime(250);
      
      await nftMint.connect(addr1).mintPublic(1, { value: PUBLIC_PRICE });
      
      const contractBalance = await ethers.provider.getBalance(await nftMint.getAddress());
      expect(contractBalance).to.equal(PUBLIC_PRICE);
      
      await expect(nftMint.withdraw())
        .to.emit(nftMint, "Withdrawal")
        .withArgs(owner.address, PUBLIC_PRICE);
      
      const finalBalance = await ethers.provider.getBalance(await nftMint.getAddress());
      expect(finalBalance).to.equal(0);
    });
    
    it("Should not allow non-owner to withdraw", async function () {
      await expect(nftMint.connect(addr1).withdraw()).to.be.reverted;
    });
  });
  
  describe("Royalty", function () {
    it("Should set default royalty", async function () {
      const royaltyInfo = await nftMint.royaltyInfo(1, ethers.parseEther("1"));
      expect(royaltyInfo[1]).to.equal(ethers.parseEther("0.05")); // 5%
    });
  });
  
  describe("Gas Optimization", function () {
    it("Should mint multiple NFTs efficiently", async function () {
      await increaseTime(250);
      
      const tx = await nftMint.connect(addr1).mintPublic(5, { value: PUBLIC_PRICE * 5n });
      const receipt = await tx.wait();
      
      console.log(`Gas used for minting 5 NFTs: ${receipt.gasUsed.toString()}`);
      expect(receipt.gasUsed).to.be.lessThan(500000n); // Should be efficient
    });
  });
});
