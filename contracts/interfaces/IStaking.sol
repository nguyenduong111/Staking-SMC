// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IStakingBonus {

  struct DateAndRate {
    uint256 date;
    uint256 rate;
  }

  struct StakingUserInfo {
        uint256 balanceStakeOf;
        uint256 timeStartStake;
        uint256 durationUser;
        uint256 IDStake;
        uint256 amountRewardClaimed;
        uint256 totalReward;
    }    

  function totalStakingBalanceOfUser(address _account) view external returns(uint256);

  function stake(uint256 _amount,uint256 _duration) external;

  function withdrawTokenStake(uint256 _ID) external;

  function claimReward(uint256 _ID) external;

  function calculateForceWithdrawBonus(uint256 _amount,uint256 _timeStartStake, uint256 _duration) external view returns(uint256);

  function calculateBonus(uint256 _amount,uint256 _duration) external view returns(uint256);

  function getAllStakeUser(address _account) view external returns(StakingUserInfo[] memory);

  function viewAmountBonusCurrent(address user, uint256 _ID) view external returns(uint256);

}