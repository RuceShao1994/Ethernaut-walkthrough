# Vault
Vault這關要求我們獲取密碼來解鎖這個合約，讓我們先來看一下代碼

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}
```
## 代码分析
代碼很簡單，合約在部署時，會將`locked` 設置為true,并且傳入`_password`作爲參數，設定一個bytes32的`private` 狀態變量`password`。

我們可以通過`unlock`函數來解鎖這個合約，只要傳入的_password和`password`相同，就可以將`locked`設置為false。

問題在于`password`是`private`的，我們無法直接從外部呼叫合約取得`password`，所以我們需要找到一個方法來獲取`password`的值。這裏涉及到EVM存儲的一個特性，也就是所有合約中的變量都是存儲在`storage`中。`private`的變量并不是查看不了，只是無法從外部直接調用，但是我們可以通過查看`storage`中`password`的存儲位置來獲取`password`的bytes32的值。

由合約的代碼可知，我們的`storage`的第一個slot存儲的是`locked`的值，是一個bool型的變量，占用32個字節，所以`password`的存儲位置是第二個slot，也就是`0x1`。

我們只需要通過`web3.eth.getStorageAt`來獲取`password`的值，就可以解鎖這個合約了。

## 攻击过程
1. 在console中使用web3.eth.getStorageAt來獲取`password`的值
```
web3.eth.getStorageAt(instance_address, 1)
```
2. 將獲取到的值傳入unlock函數，解鎖合約
3. 完成任務
