// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "./lib/BEP20.sol";
import "./lib/IBEP20.sol";

import "@pancakeswap/core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap/core/contracts/interfaces/IPancakePair.sol";
import "@pancakeswap/periphery/contracts/libraries/PancakeLibrary.sol";

contract Token is BEP20 {
  address public immutable WETH;

  address public immutable FACTORY;
  address public immutable PAIR;

  uint256 public stakingAPY;

  error RequireToUnstake;
  error RequireToStake;

  struct YieldInfo {
    uint256 amount;
    uint256 lastBlock;
  }

  mapping(address => YieldInfo) yieldInfo;

  constructor(
    address _factory,
    address _WETH
  ) ERC20("Token", "TKN") {
    FACTORY = _factory;
    WETH = _WETH;

    stakingAPY = 10;

    IPancakeFactory(FACTORY).createPair(address(this), WETH);
    PAIR = PancakeLibrary.pairFor(FACTORY, address(this), WETH);

    _mint(msg.sender, initialSupply);
  }

  function stakeLpToken(uint256 amount_) external {
    if ( yieldInfo[msg.sender].amount > 0 ) revert RequireToUnstake();

    yieldInfo[msg.sender].amount += amount_;
    yieldInfo[msg.sender].lastBlock += block.timestamp;

    IPancakePair(PAIR).approve(address(this), amount_);
    IPancakePair(PAIR).transferFrom(msg.sender, address(this), amount_);
  }

  function unStakeLpToken() external {
    if ( yieldInfo[msg.sender].amount <= 0 ) revert RequireToStake();

    yieldInfo[msg.sender].amount += 0;
    yieldInfo[msg.sender].lastBlock += 0;

    IPancakePair(PAIR).approve(msg.sender, amount_);
    IPancakePair(PAIR).transferFrom(address(this), msg.sender, amount_);
  }
}