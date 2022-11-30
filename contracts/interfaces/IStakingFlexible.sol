// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IStakingFlexible {

    struct StakeInfo {
        uint256 amount;
        uint256 apr;
        uint256 startTime;
        uint256 timeClaimed;
        uint256 ID;
    }

  event Stake(address user, uint256 _amount, uint256 _startTime, uint256 rate, uint256 ID);
  event ClaimReward(address user, uint256 _amount, uint256 _claimTime);
  event WithdrawTokenStake(address user, uint256 _amount, uint256 _claimTime);
  event SendRewardByAdmin(address user, uint256 _amount, uint256 timestamp);
  event WithdrawnByAdmin(address user, uint256 _amount, uint256 timestamp);
  event SetApr(address admin, uint256 apr, uint256 timestamp);

    // admin function
    
    function setApr(uint256 _apr) external;

    function sendTokenReward(uint256 _amount) external;

    function withdrawTokenAdmin(uint256 _amount) external;

    // user function

    function stakeToken(uint256 _amount) external;

    function claimReward(uint256 _index) external;

    function withdrawTokenStake(uint256 _index) external;

    // view function

    function getApr() external view returns(uint256);

    function getTotalRewardPool() external view returns(uint256);

    function showListStakeUser(address _user) external view returns(StakeInfo[] memory);

    function viewAmountBonusCurrent(address _user, uint256 _ID) external view returns(uint256);

}