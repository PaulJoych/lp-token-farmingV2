// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/BEP20.sol";
import "./lib/IBEP20.sol";
import "./lib/SafeBEP20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@pancakeswap/core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap/periphery/contracts/interfaces/IPancakeRouter02.sol";

contract TokenFarmPool is Ownable {
  error RequireDayTimelength();
  error RequireToUnstake();
  error RequireToStake();

  IPancakeFactory v2Factory;
  IPancakeRouter02 v2Router;


  address v2Pair;
  address public immutable mToken;
  address public immutable rToken;

  uint256 public stakingAPY;

  struct YieldInfo {
    uint256 amount;
    uint256 timeStamp;
  }

  mapping(address => YieldInfo) yieldInfo;

  constructor(
    address _v2Router,
    address _mToken,
    address _rToken
  ) {
    mToken = _mToken;
    rToken = _rToken;

    v2Router = IPancakeRouter02(_v2Router);
    v2Factory = IPancakeFactory(v2Router.factory());
    v2Pair = v2Factory.createPair(mToken, v2Router.WETH());

    stakingAPY = 10;
  }

  function stakeLpToken(uint256 amount_) external {
    if ( yieldInfo[msg.sender].amount > 0 ) revert RequireToUnstake();

    yieldInfo[msg.sender].amount += amount_;
    yieldInfo[msg.sender].timeStamp = block.timestamp;

    SafeBEP20.safeApprove(IBEP20(v2Pair), address(this), amount_);
    SafeBEP20.safeTransferFrom(IBEP20(v2Pair), msg.sender, address(this), amount_);
  }

  function unStakeLpToken() external {
    uint256 amount = yieldInfo[msg.sender].amount;
    if ( amount <= 0 ) revert RequireToStake();

    uint256 reward = calculateReward();

    yieldInfo[msg.sender].amount = 0;
    yieldInfo[msg.sender].timeStamp = 0;

    BEP20(rToken).mint(reward);
    SafeBEP20.safeApprove(IBEP20(rToken), msg.sender, reward);
    SafeBEP20.safeTransferFrom(IBEP20(rToken), address(this), msg.sender, reward);

    SafeBEP20.safeApprove(IBEP20(v2Pair), msg.sender, amount);
    SafeBEP20.safeTransferFrom(IBEP20(v2Pair), address(this), msg.sender, amount);
  }

  function farm() external {
    uint256 reward = calculateReward();

    yieldInfo[msg.sender].timeStamp = block.timestamp;

    BEP20(rToken).mint(reward);
    SafeBEP20.safeApprove(IBEP20(rToken), msg.sender, reward);
    SafeBEP20.safeTransferFrom(IBEP20(rToken), address(this), msg.sender, reward);
  }

  function calculateReward() internal view returns (uint256) {
    YieldInfo memory info = yieldInfo[msg.sender];
    if ( info.amount < 0 ) revert RequireToStake();
    if (((block.timestamp - info.timeStamp) / 1 days) < 1) revert RequireDayTimelength();

    return ((block.timestamp - info.timeStamp) / 1 days) * (info.amount * ((stakingAPY / 100) / 365)) ;
  }

  function setAPY(uint256 stakingAPY_) external onlyOwner {
    stakingAPY = stakingAPY_;
  }
}