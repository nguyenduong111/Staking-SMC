// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IStaking.sol";

contract StakingBonus is IStakingBonus {

    using Counters for Counters.Counter;
    Counters.Counter public ID;
    IERC20 public tokenA;
    IERC20 public tokenB;
    address public owner;
    uint256 minTimeToReward = 60;   // 10s 
    uint256 public bonusWillPay = 0;
    DateAndRate[] public date;
    uint256 public divisor = 1000000000;
    
    mapping(address => StakingUserInfo[]) private stakingUserInfo;
    mapping(uint256 => uint256) private dateToRate; 

    constructor(address _tokenA, address _tokenB, uint256[] memory _date, uint256[] memory _rate) checkInputArray(_date.length, _rate.length) {
        owner = msg.sender;
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        for(uint256 i = 0; i < _date.length; i ++) {
          date.push(DateAndRate(_date[i], _rate[i]));
          dateToRate[_date[i]] = _rate[i];
        }
    }

    function totalStakingBalanceOfUser(address _account) view public override returns(uint256){
        uint256 total;
        for(uint256 i = 0;i < stakingUserInfo[_account].length; i++){
            total += stakingUserInfo[_account][i].balanceStakeOf;
        }
        return total;
    }

    function _findStake(address _account, uint256 _ID) view private returns(StakingUserInfo storage){
        for(uint256 i=0;i< stakingUserInfo[_account].length; i++){
            if(_ID == stakingUserInfo[_account][i].IDStake){
                return stakingUserInfo[_account][i];
            }
        }
        revert('Not found');
    }

    function _addStakeOfUser(uint256 _balanceStakeOf, uint256 _timeStartStake, uint256 _durationUser,address _account) private {
        uint256 totalReward = calculateBonus( _balanceStakeOf,_durationUser);
        StakingUserInfo memory newStake = StakingUserInfo(_balanceStakeOf,_timeStartStake,_durationUser,ID.current(),0,totalReward);
        stakingUserInfo[_account].push(newStake);
        ID.increment();
    }

    
    function stake(uint256 _amount,uint256 _duration) requireStartStaking(_amount,_duration) public override { 
        uint256 _timeStartStake = block.timestamp;
        _addStakeOfUser(_amount,_timeStartStake, _duration, msg.sender);
        tokenA.transferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount, _duration);
    }

    
    function withdrawTokenStake(uint256 _ID) public override resetStakeOfUser(_ID){
        StakingUserInfo memory data = _findStake(msg.sender, _ID);
        uint256 duration = data.durationUser;
        uint256 startTime = data.timeStartStake;
        require(startTime + duration < block.timestamp ,"haven't time yet");
        if(data.totalReward - data.amountRewardClaimed != 0) {
          tokenB.transfer(msg.sender, data.totalReward - data.amountRewardClaimed);
        }
          
        tokenA.transfer(msg.sender, data.balanceStakeOf);
        emit WithdrawTokenStake(msg.sender, data.balanceStakeOf, _ID);
    }

    function claimReward(uint256 _ID) public override {
        StakingUserInfo storage data = _findStake(msg.sender, _ID);
        require(data.amountRewardClaimed < data.totalReward, "bonus has been withdrawn");
        uint256 duration = data.durationUser;
        uint256 startTime = data.timeStartStake;
        uint256 amount = data.balanceStakeOf;
        uint256 bonus = 0;
        uint256 totalRewardClaimed = data.amountRewardClaimed;

        if(block.timestamp - startTime >= duration) {
          bonus = calculateBonus(amount, duration) - totalRewardClaimed;
        }else {
          bonus = calculateForceWithdrawBonus(amount, startTime, duration) - totalRewardClaimed;
        }
        require(tokenB.balanceOf(address(this)) >= bonus,"not enough balance");
        data.amountRewardClaimed += bonus;
        tokenB.transfer(msg.sender, bonus);
        emit ClaimReward(msg.sender, bonus, _ID);
    }

    modifier checkInputArray (uint256 _date, uint256 _rate) {
      require(_date == _rate, "array length date must be equal array length rate");
      _;
    }

    modifier resetStakeOfUser(uint256 _ID){
        _;
        uint256 bonus = calculateBonus(_findStake(msg.sender,_ID).balanceStakeOf,_findStake(msg.sender,_ID).durationUser);
        bonusWillPay -= bonus;
        bool check = false;
        uint256 stakeLength = stakingUserInfo[msg.sender].length;
        for(uint256 i=0;i< stakeLength; i++){
            if(_ID == stakingUserInfo[msg.sender][i].IDStake){
                stakingUserInfo[msg.sender][i] = stakingUserInfo[msg.sender][stakeLength - 1];
                check = true;
            }
        }
        if(check){
            stakingUserInfo[msg.sender].pop();
        }
    }

    modifier requireStartStaking(uint256 _amount,uint256 _duration){
        bool checkDuration = false;
        for(uint256 i = 0; i < date.length; i ++) {
          if(_duration == date[i].date) {
            checkDuration = true;
            break;
          }
        }
        require(checkDuration, "wrong duration");
        require(_amount > 0, "amount = 0");
        bonusWillPay += calculateBonus( _amount,_duration);
        require(tokenB.balanceOf(address(this)) >= bonusWillPay,"not enough balance to pay reward");
        _;
    }

    function calculateForceWithdrawBonus(uint256 _amount,uint256 _timeStartStake, uint256 _duration) public view override returns(uint256 bonus){
        // describe how many `10 second` passed
        uint256 cycleBonus = (block.timestamp - _timeStartStake) / minTimeToReward;
        // every 10 second equal 1% rate bonus
        uint256 rate = (_amount * dateToRate[_duration] * minTimeToReward ) / (divisor * _duration);
        bonus = cycleBonus*rate;
        return bonus;
    }

    function calculateBonus(uint256 _amount,uint256 _duration) public view override returns(uint256 bonus){
      bool checkDuration = false;
        for(uint256 i = 0; i < date.length; i ++) {
          if(_duration == date[i].date) {
            bonus = _amount * date[i].rate / divisor;
            checkDuration = true;
            break;
          }
        }
        require(checkDuration, "wrong duration in calculateBonus");

        return bonus;
    }
    
    
    function getAllStakeUser(address _account) view public override returns(StakingUserInfo[] memory){ 
        return stakingUserInfo[_account];
    }

    
    function viewTimeUntilWithDrawFullTime(address _account,uint256 _ID) view public returns(uint256){ 
        return _findStake(_account,_ID).timeStartStake + _findStake(_account,_ID).durationUser - block.timestamp;
    }

    function viewAmountBonusCurrent(address user, uint256 _ID) view public override returns(uint256 bonus) {
      StakingUserInfo memory data = _findStake(user, _ID);
      uint256 duration = data.durationUser;
      uint256 startTime = data.timeStartStake;
      uint256 amount = data.balanceStakeOf;
      uint256 totalRewardClaimed = data.amountRewardClaimed;


      if(block.timestamp - startTime >= duration) {
        bonus = calculateBonus(amount, duration) - totalRewardClaimed;
      }else {
        bonus = calculateForceWithdrawBonus(amount, startTime, duration) - totalRewardClaimed;
      }

      return bonus;
    }

    function viewMaxRewardPool() view public override returns(uint256) {
      return tokenB.balanceOf(address(this)) - bonusWillPay;
    }

}