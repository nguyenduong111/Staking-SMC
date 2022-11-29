// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStakingFlexible.sol";

contract StakingFlexible is Ownable, IStakingFlexible {

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

    function withdrawToken(uint256 _amount) public override onlyOwner {
        require(_amount <= totalRewardPool, "not enough token to withdraw");
        token.transfer(msg.sender, _amount);
        totalRewardPool -= _amount;
        emit WithdrawnByAdmin(msg.sender, _amount, block.timestamp);
    }

// private function
    function removeItemArray(address _user, uint256 _index) private {
        uint256 size = listStakeUser[_user].length;

        for(uint256 i = 0; i < size; i ++) {
            if(i == _index) {
                listStakeUser[_user][i] = listStakeUser[_user][size - 1];
                listStakeUser[_user].pop();
                break;
            }
        }
    }

    function _claimReward(address _user, uint256 _index, uint256 _claimTime) private {
        StakeInfo memory dataUser = listStakeUser[_user][_index];

        uint256 bonus = (dataUser.amount * dataUser.apr * (_claimTime - dataUser.startTime)) / (minTimeToReward * divisor);
        require(bonus <= totalRewardPool, "not enough token to reward, please notify admin");
        token.transfer(_user, bonus + dataUser.amount);
        removeItemArray(_user, _index);
        totalRewardPool -= bonus;

        emit ClaimReward(_user, bonus + dataUser.amount, _claimTime);
    }    

    // user function
    function stakeToken(uint256 _amount) public override {
        require(token.allowance(msg.sender, address(this)) >= _amount, "not enough token approve to stake");
        token.transferFrom(msg.sender, address(this), _amount);
        StakeInfo memory dataStake = StakeInfo(_amount, apr, block.timestamp);
        listStakeUser[msg.sender].push(dataStake);
        emit Stake(msg.sender, _amount, block.timestamp , apr);
    }

    function claimReward(uint256 _index) public override {
        uint256 size = listStakeUser[msg.sender].length;
        require (_index < size, "index incorrect");
        uint256 claimTime = block.timestamp;

        _claimReward(msg.sender, _index, claimTime);
        
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

    function viewAmountBonusCurrent(uint256 _index) public view override returns(uint256) {
        uint256 size = listStakeUser[msg.sender].length;
        require (_index < size, "index incorrect");
        StakeInfo memory dataUser = listStakeUser[msg.sender][_index];
        uint256 claimTime = block.timestamp;
        uint256 bonus = (dataUser.amount * dataUser.apr * (claimTime - dataUser.startTime)) / (minTimeToReward * divisor);
    
        return bonus;
    }

    
}