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

	constructor(address taxationWallet, uint multiplierValue) ERC20("VirmApp", "TRT"){
        _taxWallet = taxationWallet; 
        _percentage_multiplier = multiplierValue; 
        _mint(msg.sender,123 ether);
    }

    function getBuyTax() public view returns (uint) {
        return _buyTax; 
    }

    function getSellTax() public view returns (uint) {
        return _sellTax; 
    }

    function setBuyTax(uint value) onlyOwner public {
        require(value > 0, "Multiplier must contain a value greater than 0"); 
        _buyTax = value; 
    }

    function setPercentageMultiplier(uint value) onlyOwner public {
        require(value > 0, "Multiplier must contain a value greater than 0"); 
        _percentage_multiplier = value;
    }

    function setSellTax(uint value) onlyOwner public {
        require(value > 0, "Multiplier must contain a value greater than 0"); 
        _sellTax = value; 
    }

    function setTaxationWallet(address wallet) onlyOwner public {
        _taxWallet = wallet; 
    }
    
    function transfer(address to, uint256 amount) override public returns (bool) {

        require(to != address(0), "This requires an address to transfer"); 

        // Process tax
        ( bool hasCalculation, uint256 valueToSubtract ) = VirmTools.getPercentageValue(_buyTax, amount, _percentage_multiplier);

        super.transfer(to, (amount - valueToSubtract));
        
        super.transfer(_taxWallet, valueToSubtract); // TODO: remove this, only a reference

        return true; 
    }
}