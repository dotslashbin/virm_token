// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library VirmTools {

	using SafeMath for uint; 

	function getPercentageValue(uint percentage, uint256 number, uint multiplier) internal pure returns(bool, uint256) {
		( bool isFirstMul, uint256 firstMulValue ) = SafeMath.tryMul((percentage * multiplier), (number * multiplier)); 

		if(isFirstMul) {
			(bool forDiv, uint256 dividedBy ) = SafeMath.tryDiv( firstMulValue, (100*multiplier)); 

			if(forDiv) {
				return SafeMath.tryDiv(dividedBy, multiplier); 
			}
		}

		return (false, 0); 
	}
}