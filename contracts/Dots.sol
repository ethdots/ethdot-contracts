// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Dots is ERC20, Ownable, Pausable {
  // solhint-disable no-empty-blocks
  constructor(string memory name_, string memory symbol_)
    ERC20("Dots", "DOTS")
  {}

  /// @notice Mint tokens to msg.sender
  /// @param amount Amount to mint
  function mint(uint256 amount) external onlyOwner {
    _mint(msg.sender, amount);
  }

  /// @notice Mint tokens to specified account
  /// @param account Account to mint the tokens to
  /// @param amount Amount to mint
  function mintTo(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }

  /// @notice Destroys `amount` tokens from the caller.
  /// @param amount to destroy
  function burn(uint256 amount) public virtual {
    _burn(msg.sender, amount);
  }

  /// @notice Destroys `amount` tokens from `account`, deducting from the caller's allowance
  /// @param account Destroy from this account
  /// @param amount Destroy this amount
  function burnFrom(address account, uint256 amount) public virtual {
    uint256 currentAllowance = allowance(account, msg.sender);
    require(currentAllowance >= amount, "EXCESS_ALLOWANCE");
    unchecked {
      _approve(account, msg.sender, currentAllowance - amount);
    }
    _burn(account, amount);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /// @dev See {ERC20-_beforeTokenTransfer} - the contract must not be paused.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), "PAUSED");
  }
}
