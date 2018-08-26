pragma solidity ^0.4.24;

import "ERC20.sol";


// ----------------------------------------------------------------------------
// MintableToken Interface = ERC20 + symbol + name + decimals + mint + burn
// + approveAndCall
// ----------------------------------------------------------------------------
contract MintableTokenInterface is ERC20 {
    function symbol() public view returns (string);
    function name() public view returns (string);
    function decimals() public view returns (uint8);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
    function mint(address tokenOwner, uint tokens) public returns (bool success);
    function burn(address tokenOwner, uint tokens) public returns (bool success);
}
