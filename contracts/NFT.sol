// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFT is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable collectionSize;
  uint256 public immutable maxBatchSize;
  uint256 public immutable maxPerAddressDuringPublicSaleMint;
  uint256 public immutable amountForDevs;

  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 publicSalePrice;
  }

  SaleConfig public saleConfig;

  constructor(
    uint256 collectionSize_,
    uint256 maxBatchSize_,
    uint256 amountForDevs_
  ) ERC721A("Sample NFT", "SMPL") {
    collectionSize = collectionSize_;
    maxBatchSize = maxBatchSize_;
    maxPerAddressDuringPublicSaleMint = maxBatchSize_;
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

  // /**
  //  * @dev Triggers emergency stop mechanism.
  //  */
  // function pause()
  //   public
  //   onlyOwner
  // {
  //   _pause();
  // }

  // /**
  //  * @dev Returns contract to normal state.
  //  */
  // function unpause()
  //   public
  //   onlyOwner
  // {
  //   _unpause();
  // }

  // function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  //   internal
  //   whenNotPaused
  //   override
  // {
  //   super._beforeTokenTransfer(from, to, tokenId);
  // }

  function startPublicSale(
    uint32 startTime,
    uint64 priceWei
  ) external onlyOwner {
    saleConfig = SaleConfig(
      startTime,
      priceWei
    );
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser
  {
    uint256 price = uint256(saleConfig.publicSalePrice);
    uint256 startTime = uint256(saleConfig.publicSaleStartTime);
    require(
      startTime != 0 && block.timestamp >= startTime,
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringPublicSaleMint,
      "can not mint this many"
    );
    uint256 totalCost = price * quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
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
}
