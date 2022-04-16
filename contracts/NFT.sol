// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFT is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxBatchSize;
  uint256 public immutable amountForDevs;

  // Constants
  uint256 public constant TOTAL_SUPPLY = 7_777;
  uint256 public constant MINT_PRICE = 0.08 ether;

  constructor(
    uint256 maxBatchSize_,
    uint256 amountForDevs_
  ) ERC721A("Sample NFT", "SMPL") {
    maxBatchSize = maxBatchSize_;
    amountForDevs = amountForDevs_;
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

  // function mintTo(address recipient)
  //   public
  //   payable
  //   returns (uint256)
  // {
  //   uint256 tokenId = currentTokenId.current();
  //   require(tokenId < TOTAL_SUPPLY, "Max supply reached");
  //   require(msg.value == MINT_PRICE, "Transaction value did not equal the mint price");

  //   currentTokenId.increment();
  //   uint256 newItemId = currentTokenId.current();
  //   _safeMint(recipient, newItemId);
  //   return newItemId;
  // }

  // function _beforeTokenTransfer(address from, address to, uint256 tokenId)
  //   internal
  //   whenNotPaused
  //   override
  // {
  //   super._beforeTokenTransfer(from, to, tokenId);
  // }

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
