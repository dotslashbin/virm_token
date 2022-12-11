// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Stakeable {
	
	struct Stake {
			address user;
			uint256 amount;
			uint256 since;
			uint256 claimable;
	}
	
	struct Stakeholder {
			address user;
			Stake[] address_stakes;
			
	}

	struct StakingSummary{
			uint256 total_amount;
			Stake[] stakes;
	}

	Stakeholder[] internal stakeholders;

	mapping(address => uint256) internal stakes;

	event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

	uint256 internal rewardPerHour = 1000; // TODO: change to a controllable variable
	
	constructor() {
			// This push is needed so we avoid index 0 causing bug of index-1
			stakeholders.push();
	}

	function _addStakeholder(address staker) internal returns (uint256){
			// Push a empty item to the Array to make space for our new stakeholder
			stakeholders.push();
			// Calculate the index of the last item in the array by Len-1
			uint256 userIndex = stakeholders.length - 1;
			// Assign the address to the new index
			stakeholders[userIndex].user = staker;
			// Add index to the stakeHolders
			stakes[staker] = userIndex;
			return userIndex; 
	}

	function _stake(uint256 _amount) internal {
			// Simple check so that user does not stake 0 
			require(_amount > 0, "Cannot stake nothing");
			
			// Mappings in solidity creates all values, but empty, so we can just check the address
			uint256 index = stakes[msg.sender];
			// block.timestamp = timestamp of the current block in seconds since the epoch
			uint256 timestamp = block.timestamp;
			// See if the staker already has a staked index or if its the first time
			if(index == 0){
					// This stakeholder stakes for the first time
					// We need to add him to the stakeHolders and also map it into the Index of the stakes
					// The index returned will be the index of the stakeholder in the stakeholders array
					index = _addStakeholder(msg.sender);
			}

			// Use the index to push a new Stake
			// push a newly created Stake with the current block timestamp.
			stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, 0));
			// Emit an event that the stake has occured
			emit Staked(msg.sender, _amount, index,timestamp);
	}

	function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
			// Grab user_index which is the index to use to grab the Stake[]
		uint256 user_index = stakes[msg.sender];
		Stake memory current_stake = stakeholders[user_index].address_stakes[index];
		require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

			// Calculate available Reward first before we start modifying data
			uint256 reward = CalculateStakeReward(current_stake);
			// Remove by subtracting the money unstaked 
			current_stake.amount = current_stake.amount - amount;
			// If stake is empty, 0, then remove it from the array of stakes
			if(current_stake.amount == 0){
					delete stakeholders[user_index].address_stakes[index];
			}else {
					// If not empty then replace the value of it
					stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
					// Reset timer of stake
				stakeholders[user_index].address_stakes[index].since = block.timestamp;    
			}

			return amount+reward;

	}

	function CalculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
			// First calculate how long the stake has been active
			// Use current seconds since epoch - the seconds since epoch the stake was made
			// The output will be duration in SECONDS ,
			// We will reward the user 0.1% per Hour So thats 0.1% per 3600 seconds
			// the alghoritm is  seconds = block.timestamp - stake seconds (block.timestap - _stake.since)
			// hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
			// we then multiply each token by the hours staked , then divide by the rewardPerHour rate 
			return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
	}
}