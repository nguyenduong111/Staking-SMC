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
        uint256 rateUser;
        uint256 IDStake;
        uint256 amountRewardClaimed;
        uint256 totalReward;
  }

  event Stake(address user, uint256 _amount, uint256 _duration, uint256 rate);
  event WithdrawTokenStake(address user, uint256 _amount, uint256 _ID);
  event ClaimReward(address user, uint256 _amount, uint256 _ID);
  event SendRewardByAdmin(address user, uint256 _amount, uint256 timestamp);
  event WithdrawnByAdmin(address user, uint256 _amount, uint256 timestamp);
  
      

  function totalStakingBalanceOfUser(address _account) view external returns(uint256);

  function stake(uint256 _amount,uint256 _duration) external;

  function withdrawTokenStake(uint256 _ID) external;

  function claimReward(uint256 _ID) external;

  function getAllStakeUser(address _account) view external returns(StakingUserInfo[] memory);

  function viewAmountBonusCurrent(address user, uint256 _ID) view external returns(uint256);

  function viewMaxRewardPool() view external returns(uint256);

  function sendRewardByAdmin(uint256 _amount) external;

  function withdrawnByAdmin(uint256 _amount) external;

  function setDateAndRate(uint256[] memory _date, uint256[] memory _rate) external;

}