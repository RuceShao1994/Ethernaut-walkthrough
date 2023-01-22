# Privacy
Privacy這一關需要我們解鎖這個合約，考察的主要是以太坊關於storage相關的知識，讓我們看一下代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) {
    data = _data;
  }
  
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }

  /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}
```
## 代碼分析
需要“解鎖”這個合約的話，主要關注的是`unlock`函數，當我們的入參`_key`是`bytes16(data[2])`的時候，就可以將合約“解鎖”。那麼我們如何獲取到`data[2]`呢？這裡用到了我們在Vault那一關使用的方式，利用`web3.eth.getStorageAt`來獲取private的變量。

那麼這個變量在storage的什麼位置呢？我們可以通過所有的變量一個一個來看：
```
//slot 0
bool public locked --- 1 bytes

//slot 1
uint256 public ID --- 32 bytes

//slot 2
uint8 private flattening --- 1 bytes
uint8 private denomination --- 1 bytes
uint16 private awkwardness --- 2 bytes

//slot 3
data[0] --- 32 bytes

//slot 4
data[1] --- 32 bytes

//slot 5
data[2] --- 32 bytes
```
所以我們可以看到，我們需要的`data[2]`在storage的第5個slot，那麼我們就可以通過`web3.eth.getStorageAt(contractAddress, 5)`來獲取到`data[2]`的值。

但是還沒有結束，因為`unlock`函數的入參是`bytes16`,而`data[2]`是`bytes32`,所以我們需要取得`data[2]`的前32個字元(2字元=1byte)，值得注意的是，這前32個字元史不包括`0x`的，所以在我們取得前32個字元后記得還要將`0x`加上。

## 攻擊過程
1. 通過`web3.eth.getStorageAt(contractAddress, 5)`獲取到data[2]的值
2. 使用`slice(0,34)`將data[2]的值轉換成bytes16

