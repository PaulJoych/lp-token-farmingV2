// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/BEP20.sol";
import "./lib/IBEP20.sol";
import "./lib/SafeBEP20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import { Token } from "./Token.sol";
import { RewardToken } from "./RewardToken.sol";

import { IPancakeFactory } from "@pancakeswap/core/contracts/interfaces/IPancakeFactory.sol";
import { IPancakePair } from  "@pancakeswap/core/contracts/interfaces/IPancakePair.sol";

contract TokenPool is Ownable {
  error RequireDayTimelength();
  error RequireToUnstake();
  error RequireToStake();

  address public immutable WETH;

  address public immutable FACTORY;
  address public immutable PAIR;

  Token mToken;
  RewardToken rToken;
  uint256 public stakingAPY;

  struct YieldInfo {
    uint256 amount;
    uint256 lastBlock;
  }

  mapping(address => YieldInfo) yieldInfo;

  constructor(
    address _factory,
    address _WETH
  ) {
    FACTORY = _factory;
    WETH = _WETH;

    stakingAPY = 10;

    IPancakeFactory(FACTORY).createPair(address(rToken), WETH);
    IPancakeFactory(FACTORY).createPair(address(mToken), WETH);
    PAIR = IPancakeFactory(FACTORY).getPair(address(mToken), WETH);
  }

  function stakeLpToken(uint256 amount_) external {
    if ( yieldInfo[msg.sender].amount > 0 ) revert RequireToUnstake();

    yieldInfo[msg.sender].amount += amount_;
    yieldInfo[msg.sender].lastBlock = block.timestamp;

    SafeBEP20.safeApprove(IBEP20(PAIR), address(this), amount_);
    SafeBEP20.safeTransferFrom(IBEP20(PAIR), msg.sender, address(this), amount_);
  }

  function unStakeLpToken() external {
    uint256 amount = yieldInfo[msg.sender].amount;
    if ( amount <= 0 ) revert RequireToStake();

    uint256 reward = calculateReward();

    yieldInfo[msg.sender].amount = 0;
    yieldInfo[msg.sender].lastBlock = 0;

    rToken.mint(reward);
    rToken.transfer(msg.sender, reward);

    SafeBEP20.safeApprove(IBEP20(PAIR), msg.sender, amount);
    SafeBEP20.safeTransferFrom(IBEP20(PAIR), address(this), msg.sender, amount);
  }

  function farm() external {
    uint256 reward = calculateReward();

    yieldInfo[msg.sender].lastBlock = block.timestamp;

    rToken.mint(reward);
    SafeBEP20.safeApprove(IBEP20(rToken), msg.sender, reward);
    SafeBEP20.safeTransferFrom(IBEP20(rToken), address(this), msg.sender, reward);
  }

  function calculateReward() internal view returns (uint256) {
    YieldInfo memory info = yieldInfo[msg.sender];
    if ( info.amount < 0 ) revert RequireToStake();
    if (((block.timestamp - info.lastBlock) / 1 days) < 1) revert RequireDayTimelength();

    return ((block.timestamp - info.lastBlock) / 1 days) * (info.amount * ((stakingAPY / 100) / 365)) ;
  }

  function setAPY(uint256 stakingAPY_) external onlyOwner {
    stakingAPY = stakingAPY_;
  }
}