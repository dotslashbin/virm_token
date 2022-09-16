// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Utils.sol"; 

contract VIRMT is ERC20, Ownable{

    using VirmTools for uint; 

    address private _taxWallet;
    uint _buyTax;
    uint _sellTax; 
    uint private _percentage_multiplier; 
    uint constant _decimal = 18; 

	constructor(address taxationWallet) ERC20("VirmApp", "VIRM"){
        _taxWallet = taxationWallet; 
        _mint(msg.sender,412 ether); // TODO: change to the correct supply, put on constants
    }

    function getBuyTax() public view returns (uint) {
        return _buyTax; 
    }

    function getSellTax() public view returns (uint) {
        return _buyTax; 
    }

    function setBuyTax(uint value) onlyOwner public {
        require(value > 0, "Multiplier must contain a value greater than 0"); 
        _buyTax = tax; 
    }

    function setPercentageMultiplier(uint value) onlyOwner public {
        require(value > 0, "Multiplier must contain a value greater than 0"); 
        _percentage_multiplier = value;
    }

    function setSellTax(uint value) onlyOwner public {
        require(value > 0, "Multiplier must contain a value greater than 0"); 
        _sellTax = tax; 
    }

    function setTaxationWallet(address wallet) onlyOwner public {
        require(wallet != 0, "There must be a valid wallet address for taxation wallet"); 
        _taxWallet = wallet; 
    }
    
    function transfer(address to, uint256 amount) override public returns (bool) {

        super.transfer(to, amount);
        super.transfer(_taxWallet, 100*10**18);

        return true; 
    }
}