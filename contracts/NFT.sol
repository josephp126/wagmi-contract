// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFT is ERC721, Pausable, Ownable {
  using Counters for Counters.Counter;

  // Constants
  uint256 public constant TOTAL_SUPPLY = 7_777;
  uint256 public constant MINT_PRICE = 0.08 ether;

  Counters.Counter private currentTokenId;

  constructor() ERC721("Sample NFT", "SMPL") {}

  /**
   * @dev Triggers emergency stop mechanism.
   */
  function pause()
    public
    onlyOwner
  {
    _pause();
  }

  function unpause()
    public
    onlyOwner
  {
    _unpause();
  }

  function mintTo(address recipient)
    public
    payable
    returns (uint256)
  {
    uint256 tokenId = currentTokenId.current();
    require(tokenId < TOTAL_SUPPLY, "Max supply reached");
    require(msg.value == MINT_PRICE, "Transaction value did not equal the mint price");

    currentTokenId.increment();
    uint256 newItemId = currentTokenId.current();
    _safeMint(recipient, newItemId);
    return newItemId;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
