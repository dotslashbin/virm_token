// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Authorizer.sol"; 

contract AdminContext {

	Authorizer _contract_authorizer; 

	constructor () {
		_contract_authorizer = new Authorizer(msg.sender); 
	}

	modifier isAuthorized() {
		require(_contract_authorizer.getDeployer() == msg.sender, "You are not authorized to make this call"); 
		_;
	}
}