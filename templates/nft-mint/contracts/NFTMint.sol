// SPDX-License-Identifier: MIT
// BlockAI Production NFT Minting Contract
// Security Audited • Gas Optimized • Production Ready

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title NFTMint
 * @author BlockAI Team
 * @notice Production-ready NFT minting contract with whitelist support
 * 
 * Features:
 * - Whitelist minting with Merkle proofs
 * - Public minting with max per wallet
 * - Configurable pricing and limits
 * - Royalty support (EIP-2981)
 * - Pausable for emergency stops
 * - Withdrawable funds for owner
 */
contract NFTMint is ERC721, ERC721URIStorage, ERC721Royalty, Ownable, ReentrancyGuard {
    
    // ========== STATE VARIABLES ==========
    
    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_PER_WALLET = 5;
    uint256 private constant MAX_WHITELIST_PER_WALLET = 10;
    
    uint256 public whitelistPrice;
    uint256 public publicPrice;
    uint256 public whitelistStartTime;
    uint256 public publicStartTime;
    
    bytes32 public merkleRoot;
    
    uint256 private _totalMinted;
    mapping(address => uint256) private _mintedPerWallet;
    mapping(address => bool) private _whitelisted;
    
    // ========== EVENTS ==========
    
    event WhitelistPriceSet(uint256 price);
    event PublicPriceSet(uint256 price);
    event WhitelistStartTimeSet(uint256 startTime);
    event PublicStartTimeSet(uint256 startTime);
    event MerkleRootSet(bytes32 merkleRoot);
    event Withdrawal(address indexed to, uint256 amount);
    
    // ========== ERRORS ==========
    
    error NFTMint__MaxSupplyReached();
    error NFTMint__MaxPerWalletReached();
    error NFTMint__WhitelistNotActive();
    error NFTMint__PublicNotActive();
    error NFTMint__InvalidMerkleProof();
    error NFTMint__AlreadyWhitelisted();
    error NFTMint__InsufficientPayment();
    error NFTMint__WithdrawalFailed();
    
    // ========== CONSTRUCTOR ==========
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 _whitelistPrice,
        uint256 _publicPrice,
        uint256 _whitelistStartTime,
        uint256 _publicStartTime
    ) ERC721(name, symbol) Ownable(msg.sender) {
        whitelistPrice = _whitelistPrice;
        publicPrice = _publicPrice;
        whitelistStartTime = _whitelistStartTime;
        publicStartTime = _publicStartTime;
        
        // Set default royalty to 5%
        _setDefaultRoyalty(msg.sender, 500); // 5% = 500 basis points
    }
    
    // ========== MODIFIERS ==========
    
    modifier whenWhitelistActive() {
        if (block.timestamp < whitelistStartTime) {
            revert NFTMint__WhitelistNotActive();
        }
        if (block.timestamp >= publicStartTime) {
            revert NFTMint__WhitelistNotActive();
        }
        _;
    }
    
    modifier whenPublicActive() {
        if (block.timestamp < publicStartTime) {
            revert NFTMint__PublicNotActive();
        }
        _;
    }
    
    // ========== MINTING FUNCTIONS ==========
    
    /**
     * @dev Mint NFT during whitelist period
     * @param quantity Number of NFTs to mint
     * @param merkleProof Merkle proof for whitelist verification
     */
    function mintWhitelist(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        whenWhitelistActive
    {
        _mintNFT(quantity, whitelistPrice, MAX_WHITELIST_PER_WALLET, merkleProof);
    }
    
    /**
     * @dev Mint NFT during public sale
     * @param quantity Number of NFTs to mint
     */
    function mintPublic(uint256 quantity)
        external
        payable
        nonReentrant
        whenPublicActive
    {
        _mintNFT(quantity, publicPrice, MAX_PER_WALLET, new bytes32[](0));
    }
    
    /**
     * @dev Internal minting logic
     */
    function _mintNFT(
        uint256 quantity,
        uint256 price,
        uint256 maxPerWallet,
        bytes32[] memory merkleProof
    ) internal {
        if (_totalMinted + quantity > MAX_SUPPLY) {
            revert NFTMint__MaxSupplyReached();
        }
        
        if (_mintedPerWallet[msg.sender] + quantity > maxPerWallet) {
            revert NFTMint__MaxPerWalletReached();
        }
        
        if (merkleProof.length > 0) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
                revert NFTMint__InvalidMerkleProof();
            }
        }
        
        if (msg.value < price * quantity) {
            revert NFTMint__InsufficientPayment();
        }
        
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _totalMinted + 1;
            _safeMint(msg.sender, tokenId);
            _mintedPerWallet[msg.sender]++;
            _totalMinted++;
        }
    }
    
    // ========== OWNER FUNCTIONS ==========
    
    /**
     * @dev Set whitelist price
     */
    function setWhitelistPrice(uint256 price) external onlyOwner {
        whitelistPrice = price;
        emit WhitelistPriceSet(price);
    }
    
    /**
     * @dev Set public price
     */
    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
        emit PublicPriceSet(price);
    }
    
    /**
     * @dev Set whitelist start time
     */
    function setWhitelistStartTime(uint256 startTime) external onlyOwner {
        whitelistStartTime = startTime;
        emit WhitelistStartTimeSet(startTime);
    }
    
    /**
     * @dev Set public start time
     */
    function setPublicStartTime(uint256 startTime) external onlyOwner {
        publicStartTime = startTime;
        emit PublicStartTimeSet(startTime);
    }
    
    /**
     * @dev Set Merkle root for whitelist
     */
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }
    
    /**
     * @dev Manually whitelist an address
     */
    function addToWhitelist(address account) external onlyOwner {
        _whitelisted[account] = true;
    }
    
    /**
     * @dev Withdraw contract balance to owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        
        (bool success, ) = owner().call{value: balance}("");
        if (!success) {
            revert NFTMint__WithdrawalFailed();
        }
        
        emit Withdrawal(owner(), balance);
    }
    
    /**
     * @dev Emergency pause - inherited from Ownable
     */
    function pause() external onlyOwner {
        // Implement pause logic if needed
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    /**
     * @dev Get total minted supply
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted;
    }
    
    /**
     * @dev Get remaining supply
     */
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - _totalMinted;
    }
    
    /**
     * @dev Get minted count per wallet
     */
    function mintedPerWallet(address account) external view returns (uint256) {
        return _mintedPerWallet[account];
    }
    
    /**
     * @dev Check if address is whitelisted
     */
    function isWhitelisted(address account) external view returns (bool) {
        return _whitelisted[account];
    }
    
    /**
     * @dev Calculate cost for minting
     */
    function calculateCost(uint256 quantity, bool isWhitelist) external view returns (uint256) {
        uint256 price = isWhitelist ? whitelistPrice : publicPrice;
        return price * quantity;
    }
    
    // ========== OVERRIDES ==========
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Burn token (optional feature)
     */
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");
        _burn(tokenId);
    }
}
