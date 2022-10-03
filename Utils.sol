// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library VirmTools {

	using SafeMath for uint; 

	function getPercentageValue(uint percentage, uint256 number, uint multiplier) internal pure returns(uint256) {
		require(percentage > 0, "You cannot have a percentage less than 0");
		require(number > 0, "You cannot have a value less than 0");
		require(multiplier > 0, "There must be an acceptible value for a multiplier"); 
		( bool isFirstMul, uint256 firstMulValue ) = SafeMath.tryMul((percentage * multiplier), (number * multiplier)); 

		if(isFirstMul) {
			(bool forDiv, uint256 dividedBy ) = SafeMath.tryDiv( firstMulValue, (100*multiplier)); 

			if(forDiv) {
				(bool success, uint256 result) = SafeMath.tryDiv(dividedBy, multiplier); 

				if(success) {
					return result;
				}

				return 0; 
			}
		}

		return 0; 
	}
}