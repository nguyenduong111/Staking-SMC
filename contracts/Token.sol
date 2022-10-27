// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    uint256 private _maxSupply;
    uint256 private _totalSupply;

    event MinterAdded(address indexed _minterAddr);
    event MinterRemoved(address indexed _minterAddr);

    mapping(address => bool) public minter;
    mapping(address => bool) public minterConsent;

    address[] private minterList;

    /**
     * @dev Sets the values for {name}, {_maxSupply} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() ERC20("TokenB", "TB") {
        uint256 fractions = 10**uint256(18);
        _maxSupply = 888888888 * fractions;
    }

    /**
     * @dev Returns the maxSupply of the token.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Issues `amount` tokens to the designated `address`.
     *
     * Can only be called by the current owner.
     * See {ERC20-_mint}.
     */
    function mint(address account, uint256 amount) public onlyOwner {
        _totalSupply = totalSupply();
        require(
            _totalSupply + amount <= _maxSupply,
            "ERC20: mint amount exceeds max supply"
        );
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

   
}