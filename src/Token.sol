// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./lib/BEP20.sol";
import "./lib/IBEP20.sol";

contract Token is BEP20 {
  constructor() BEP20("Token", "TKN") {
    _mint(msg.sender, 1000000);
  }
}