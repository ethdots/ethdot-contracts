// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/Base64.sol";

// solhint-disable quotes
contract DotsNFT is ERC721Enumerable, Ownable, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Base64 for bytes;

  uint256 public mintPrice = 0;
  uint256 public maxMintsPerTx = 10;
  uint256 public nextTokenId = 0;
  uint256 public maxPerOwner = type(uint256).max;

  // solhint-disable-next-line no-empty-blocks
  constructor() ERC721("Dots", "DOTS") {}

  event MintPriceSet(uint256 newPrice);
  event MaxMintsPerTxSet(uint256 maxMints);
  event MaxPerOwnerSet(uint256 maxPerOwner);
  event ETHExit(address to, uint256 amount);
  event ERC20Exit(address token, address to, uint256 amount);

  /// @notice Mint DOTS
  /// @param amtToMint The number of DOTS to mint
  function mint(uint256 amtToMint) external payable {
    _mintTo(msg.sender, amtToMint);
  }

  /// @notice Mint DOTS to an address
  /// @param amtToMint The number of DOTS to mint
  /// @param to Address to mint the DOTS to
  function mintTo(uint256 amtToMint, address to) external payable {
    _mintTo(to, amtToMint);
  }

  /// @notice Burns the specified tokenId. Must be approved or the owner.
  /// @param tokenId Token Id to burn
  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "NOT_OWNER_APPROVED");
    _burn(tokenId);
  }

  function ethExit(address payable to, uint256 amount) external onlyOwner {
    require(to != address(0), "NO_BURN");
    require(address(this).balance > 0, "NO_FUNDS");
    require(amount > 0, "INVALID_AMOUNT");
    require(to.send(amount), "SEND_FAIL");

    emit ETHExit(to, amount);
  }

  function erc20Exit(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    require(to != address(0), "NO_BURN");
    require(token != address(0), "INVALID_TOKEN");
    require(amount > 0, "INVALID_AMOUNT");
    require(IERC20(token).balanceOf(address(this)) > 0, "NO_FUNDS");

    IERC20(token).safeTransfer(to, amount);

    emit ERC20Exit(token, to, amount);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function getPlot(uint256 tokenId)
    public
    view
    returns (
      uint256[100] memory xs,
      uint256[100] memory ys,
      uint256 numOfDots
    )
  {
    numOfDots =
      random(string(abi.encodePacked(toString(tokenId), address(this)))) %
      100;

    for (uint256 i = 0; i < numOfDots; i++) {
      uint256 x = random(
        string(
          abi.encodePacked(toString(tokenId), address(this), "x", toString(i))
        )
      ) % 350;
      uint256 y = random(
        string(
          abi.encodePacked(toString(tokenId), address(this), "y", toString(i))
        )
      ) % 350;

      xs[i] = x;
      ys[i] = y;
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    string memory imgParts = string(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect width="100%" height="100%" fill="black" /><style>svg{width:350px;height:350px;}</style>'
      )
    );

    (
      uint256[100] memory xs,
      uint256[100] memory ys,
      uint256 numOfDots
    ) = getPlot(tokenId);

    for (uint256 i = 0; i < numOfDots; i++) {
      imgParts = string(
        abi.encodePacked(
          imgParts,
          '<circle cx="',
          toString(xs[i]),
          '" cy="',
          toString(ys[i]),
          '" r="1" stroke-width="0" fill="white" />'
        )
      );
    }

    imgParts = string(abi.encodePacked(imgParts, "</svg>"));

    string memory attributesOutput = string(
      abi.encodePacked(
        '[{"trait_type":"Dots","value":"',
        toString(numOfDots),
        '"}]'
      )
    );

    string memory json = bytes(
      string(
        abi.encodePacked(
          '{"name": "ETH Dots #',
          toString(tokenId),
          '", "description": "A simple plot. Infinite possibilities.", "attributes": ',
          attributesOutput,
          ', "image": "data:image/svg+xml;base64,',
          bytes(imgParts).base64Encode(),
          '"}'
        )
      )
    ).base64Encode();

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }

  /// @notice Update the maximum per owner limit
  /// @param _max New max allowed per owner
  function setMaxPerOwner(uint256 _max) external onlyOwner {
    maxPerOwner = _max;

    emit MaxPerOwnerSet(_max);
  }

  /// @notice Update the mint price
  /// @param _price New price in ETH
  function setMintPrice(uint256 _price) external onlyOwner {
    mintPrice = _price;

    emit MintPriceSet(_price);
  }

  /// @notice Update the maximum mints per transaction
  /// @param _maxMints New maximum mints per transaction
  function setMaxMintsPerTx(uint256 _maxMints) external onlyOwner {
    maxMintsPerTx = _maxMints;

    emit MaxMintsPerTxSet(_maxMints);
  }

  /// @dev See {ERC721-_beforeTokenTransfer}. the contract must not be paused.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    require(!paused(), "ALREADY_PAUSED");
  }

  /// @dev All checks and functionality for minting the token
  function _mintTo(address to, uint256 amtToMint) internal {
    require(amtToMint > 0, "MUST_MINT_ONE");
    require(amtToMint <= maxMintsPerTx, "TOO_MANY");
    require(msg.value == (amtToMint * mintPrice), "INVALID_FUNDS");
    require(balanceOf(to).add(amtToMint) <= maxPerOwner, "MAX_PER_OWNER");

    for (uint256 i = 0; i < amtToMint; i++) {
      _safeMint(to, nextTokenId + i);
    }
    nextTokenId += amtToMint;
  }

  /// @dev Convert a number to a display string
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /// @dev Generate a random number based on the string input
  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
}
