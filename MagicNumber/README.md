# Magic Number
Magic Number 需要我們用操作碼編寫并且部署合約，并且讓合約永遠返回42。這要求我們操作碼有一定的瞭解，還需要對EVM有比較深入的理解。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {

  address public solver;

  constructor() {}

  function setSolver(address _solver) public {
    solver = _solver;
  }

  /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
  */
}
```
## 代碼分析
如開篇所説，我們首先需要知道以太坊在創建合約時的背後過程：
1. 用戶發送給以太坊網絡一個轉賬，這個轉賬不是普通的`send`或者是`call` transaction，而是會告知EVM這個轉賬是一個`contract creation`。
2. EVM將合約代碼將以Solidity編寫的合約代碼編譯成bytecode, 這個bytecode可以直接轉換為操作碼，在一個調用棧中執行。bytecode中包括了以初始代碼（initiation code）和運行代碼（runtime code)，并且這兩者以前面初始代碼-運行代碼的順序串聯。
3. 在合約創建時，EVM只會執行初始代碼，直到達到在棧中遇到第一個`STOP`或者`RETURN`指令。簡單來説，就是合約的`constructor`被執行，并且擁有了地址。
4. 在初始代碼執行完之後，只有運行代碼會留在棧中，接著這些代碼會被複製到`memory`中，并且返回給EVM。
5. 最終EVM會將返回的代碼和新的合約地址保存在狀態存儲(state storage)中，未來對於運行代碼的調用都會在棧中執行。

瞭解了整個過程后，記住我們的目的，返回數值42。所以我們也需要編寫一個智能合約用於返回這個數值，編寫智能合約的步驟也可以分爲兩部分：
1. Initiation code: 用於創建合約，并且保存運行代碼。
2. Runtime code: 返回0x2a(42的16進制表示)。

我們可以先梳理一下運行代碼的結構：
1. 我們需要返回`0x42`，則我們需要一個代表`RETURN`的操作碼，關於EVM的操作碼，可以查看[官方文檔](https://ethereum.org/en/developers/docs/evm/opcodes/)以及[bytecode和opcode轉換表](https://github.com/crytic/evm-opcodes)。`RETURN`需要我們返回的數值保存在`memory`中，而并不像其他語言一樣可以直接從棧中彈出（`pop`)，所以我們需要將`0x2a`保存在`memory`中。保存進`memory`需要用到操作碼`MSTORE`,而`MSTORE`需要兩個參數（[具體介紹看這](https://docs.soliditylang.org/en/v0.8.17/yul.html#evm-dialect)），一個是`v`，一個是`p`。`p`是指在内存中保存的位置，`v`是指保存的值。所以我們需要一個操作碼`PUSH1`，將`0x2a`推入棧中，然後一個操作碼`PUSH1`，將`0x00`推入棧中，然後一個操作碼`MSTORE`，將棧中的值保存在`memory`中。

```
602a // PUSH1 0x2a
6000 // PUSH1 0x00
52 // MSTORE
```
這一步份的操作碼則是`602a600052`。

2. 接下來我們需要將`0x2a`返回，則我們需要使用`RETURN`,`RETURN`也需要兩個參數，一個是`p`，一個是`s`, `p`是值在`memory`存儲的位置，`s`是返回數值在`byte32`的長度。我們需要返回`42`，是`uint`,那麽`bytes`的長度為`32`，那麽就是先`PUSH1` `0x20`, 接著需要將`0x00`推入棧中，隨後使用`RETURN`操作碼。

```
6020 // PUSH1 0x20
6000 // PUSH1 0x00
f3 // RETURN
```
這一部分的操作碼則是`60206000f3`。
那麽整個運行代碼就是`602a60005260206000f3`。

接下來我們需要編寫初始代碼，初始代碼要做的就是將運行代碼複製到`memory`中。達成這一步需要使用到`copycode`這個操作碼，`copycode(t,f,s)`需要三個參數，`t`代表内存的位置，`f`代表被複製代碼的位置，`s`表示的需要多少`bytes`的代碼被複製。在這個情境下，由於我們並不知道初始代碼需要占用多少位置，所以`f`需要我們先用`placeholder`暫時代替。運行代碼一共10bytes長，所以`s`為`0x0a`。`t`是`0x00`,意味著我們將運行代碼複製到`memory`的第一個slot。

```
600a // PUSH1 0x0a
60pp // PUSH1 0xpp pp代表placeholder
6000 // PUSH1 0x00
39 // CODECOPY
```
由上可知，我們的初始代碼為`600a60pp600039`,一共12bytes長，所以我們的運行代碼從`0x0c`(12)開始，那麽60pp則爲`600c`。

接下來我們需要將内存位置`0x00`的運行代碼返回給EVM,這裏依舊使用`RETURN`
```
600a // PUSH1 0x0a
6000 // PUSH1 0x00
f3 // RETURN
```

所以綜上，合約的代碼為(記得在開始加上0x)`0x600a600c600039600a6000f3602a60805260206080f3`

## 攻擊過程
1. 使用console,使用`await web3.eth.sendTransaction({from:player,data:"0x600a600c600039600a6000f3602A60805260206080f3"});`部署合約。
2. 獲得部署后的合約地址，可以通過etherscan直接查詢到。
3. 使用`contract.setSolver(ContractAddress)`,完成任務。


