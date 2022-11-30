// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStakingFlexible.sol";

contract StakingFlexible is Ownable, IStakingFlexible {
    
    using Counters for Counters.Counter;
    Counters.Counter public ID;
    mapping(address => StakeInfo[]) private listStakeUser;
    
    IERC20 public token;
    uint256 private apr;
    uint256 private totalRewardPool;
    uint256 private minTimeToReward = 60;

    uint256 public divisor = 1000000000;
    
    constructor(address _erc20) {
        token = IERC20(_erc20);
    }

    // admin function
    function setApr(uint256 _apr) public override onlyOwner {
        apr = _apr;
        emit SetApr(msg.sender, _apr, block.timestamp);
    }

    function sendTokenReward(uint256 _amount) public override onlyOwner {
        token.transferFrom(msg.sender, address(this), _amount);
        totalRewardPool += _amount;
        emit SendRewardByAdmin(msg.sender, _amount, block.timestamp);
    }

    function withdrawTokenAdmin(uint256 _amount) public override onlyOwner {
        require(_amount <= totalRewardPool, "not enough token to withdraw");
        token.transfer(msg.sender, _amount);
        totalRewardPool -= _amount;
        emit WithdrawnByAdmin(msg.sender, _amount, block.timestamp);
    }

// private function
    function _removeItemArray(address _user, uint256 _ID) private {
        uint256 size = listStakeUser[_user].length;

        for(uint256 i = 0; i < size; i ++) {
            if(_ID == listStakeUser[_user][i].ID) {
                listStakeUser[_user][i] = listStakeUser[_user][size - 1];
                listStakeUser[_user].pop();
                break;
            }
        }
    }

    function _findStake(address _account, uint256 _ID) view private returns(StakeInfo storage){
        for(uint256 i = 0;i < listStakeUser[_account].length; i++){
            if(_ID == listStakeUser[_account][i].ID){
                return listStakeUser[_account][i];
            }
        }
        revert('Not found');
    }

    function _claimReward(address _user, uint256 _ID, uint256 _claimTime) private {
        StakeInfo storage dataUser = _findStake(_user, _ID);
        uint256 calTime = (_claimTime - dataUser.timeClaimed) / minTimeToReward;
        uint256 bonus = (dataUser.amount * dataUser.apr * calTime) / divisor;
        require(bonus <= totalRewardPool, "not enough token to reward, please notify admin");
        token.transfer(_user, bonus);
        dataUser.timeClaimed = _claimTime;
        totalRewardPool -= bonus;

        emit ClaimReward(_user, bonus, _claimTime);
    }    

    function _withdrawTokenStake(address _user, uint256 _ID, uint256 _claimTime) private {
        StakeInfo storage dataUser = _findStake(_user, _ID);
        uint256 calTime = (_claimTime - dataUser.timeClaimed) / minTimeToReward;
        uint256 bonus = (dataUser.amount * dataUser.apr * calTime) / divisor;
        require(bonus <= totalRewardPool, "not enough token to reward, please notify admin");
        token.transfer(_user, bonus + dataUser.amount);
        totalRewardPool -= bonus;
        _removeItemArray(_user, _ID);

        emit WithdrawTokenStake(_user, dataUser.amount + bonus, _claimTime);
    }

    // user function
    function stakeToken(uint256 _amount) public override {
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 time = block.timestamp;
        StakeInfo memory dataStake = StakeInfo(_amount, apr, time, time, ID.current());
        ID.increment();
        listStakeUser[msg.sender].push(dataStake);
        emit Stake(msg.sender, _amount, block.timestamp , apr, dataStake.ID);
    }

    function claimReward(uint256 _ID) public override {
        uint256 claimTime = block.timestamp;
        _claimReward(msg.sender, _ID, claimTime);

    }

    function withdrawTokenStake(uint256 _ID) public override {
        uint256 claimTime = block.timestamp;
        _withdrawTokenStake(msg.sender, _ID, claimTime);
    }

    // view function
    function getApr() public view override returns(uint256) {
        return apr;
    }

    function getTotalRewardPool() public view override returns(uint256) {
        return totalRewardPool;
    }

    function showListStakeUser(address _user) public view override returns(StakeInfo[] memory) {
        return listStakeUser[_user];
    }

    function viewAmountBonusCurrent(address _user, uint256 _ID) public view override returns(uint256) {
        StakeInfo memory dataUser = _findStake(_user, _ID);
        uint256 time = block.timestamp;
        uint256 calTime = (time - dataUser.timeClaimed) / minTimeToReward;
        uint256 bonus = (dataUser.amount * dataUser.apr * calTime) / divisor;
        return bonus;
    }

    
}