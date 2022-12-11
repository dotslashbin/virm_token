// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract VirmAdmin {
	address[] internal _taxExcemptedWallets;

	function _FetchExcemptedWallets() internal view returns(address[] memory) {
		return _taxExcemptedWallets;
	}

	function _IsWalletExcempted(address value) internal view returns(bool){
		for (uint iterator = 0; iterator < _taxExcemptedWallets.length; iterator++) {
			if(_taxExcemptedWallets[iterator] == value) {
				return true;
			}
		}

		return false;
	}

	function _InitTaxExcemptionForAddress(address value) internal {
		_taxExcemptedWallets.push(value);
	} 

}	