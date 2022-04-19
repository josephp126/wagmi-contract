// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is Ownable, ERC721A, Pausable, ReentrancyGuard {
  uint256 public immutable collectionSize;
  uint256 public immutable maxBatchSize;
  uint256 public immutable amountForDevs;

  struct SaleConfig {
    bytes32 merkleRoot;
    uint32 whitelistSaleStartTime;
    uint32 publicSaleStartTime;
    uint64 whitelistSalePrice;
    uint64 publicSalePrice;
    uint8 maxPerAddressDuringWhitelistSaleMint;
    uint8 maxPerAddressDuringPublicSaleMint;
  }

  SaleConfig public saleConfig;

  string private _baseTokenURI;

  constructor(
    uint256 collectionSize_,
    uint256 maxBatchSize_,
    uint256 amountForDevs_
  ) ERC721A("Sample NFT", "SMPL") {
    collectionSize = collectionSize_;
    maxBatchSize = maxBatchSize_;
    amountForDevs = amountForDevs_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "need to send more ETH");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  /**
   * @dev Triggers emergency stop mechanism.
   */
  function pause() external onlyOwner
  {
    _pause();
  }

  /**
   * @dev Returns contract to normal state.
   */
  function unpause() external onlyOwner
  {
    _unpause();
  }

  /**
    * @dev Hook that is called before minting and burning one token.
  */
  function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
  ) internal virtual whenNotPaused override {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  function setupWhitelistSale(
    uint32 whitelistSaleStartTime,
    uint64 whitelistSalePriveWei,
    uint8 maxPerAddressDuringWhitelistSaleMint
  ) external onlyOwner {
    saleConfig.whitelistSaleStartTime = whitelistSaleStartTime;
    saleConfig.whitelistSalePrice = whitelistSalePriveWei;
    saleConfig.maxPerAddressDuringWhitelistSaleMint
      = maxPerAddressDuringWhitelistSaleMint;
  }

  function whitelistSaleMint(
    bytes32[] calldata _merkleProof,
    uint256 quantity
  ) external payable callerIsUser {
    uint256 price = uint256(saleConfig.whitelistSalePrice);
    uint256 saleStartTime = uint256(saleConfig.whitelistSaleStartTime);
    uint256 maxPerAddress
      = uint256(saleConfig.maxPerAddressDuringWhitelistSaleMint);
    require(price != 0, "whitelist sale has not begun yet");
    require(
      saleStartTime != 0 && block.timestamp >= saleStartTime,
      "whitelist sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    bytes32 leaf = keccak256 (abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(_merkleProof, saleConfig.merkleRoot, leaf),
      "invalid whitelist proof"
    );
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddress,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity);
  }

  function endWhitelistSaleAndSetupPublicSaleInfo(
    uint32 publicSaleStartTime,
    uint64 publicSalePriceWei,
    uint8 maxPerAddressDuringPublicSaleMint
  ) external onlyOwner {
    saleConfig = SaleConfig(
      "",
      0,
      publicSaleStartTime,
      0,
      publicSalePriceWei,
      0,
      maxPerAddressDuringPublicSaleMint
    );
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser
  {
    uint256 price = uint256(saleConfig.publicSalePrice);
    uint256 startTime = uint256(saleConfig.publicSaleStartTime);
    uint256 maxPerAddress
      = uint256(saleConfig.maxPerAddressDuringPublicSaleMint);
    require(price != 0, "public sale has not begun yet");
    require(
      startTime != 0 && block.timestamp >= startTime,
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddress,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity);
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "transfer failed");
  }
}
