# Fallback

在這一關中要求我們成爲目標合約的owner，并且取出所有的餘額，主要考察的是我們對於fallback以及其他特殊函數的理解。我們可以先看一下合約的代碼，然後再來進行分析。

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {

  mapping(address => uint) public contributions;
  address public owner;

  constructor() {
    owner = msg.sender;
    contributions[msg.sender] = 1000 * (1 ether);
  }

  modifier onlyOwner {
        require(
            msg.sender == owner,
            "caller is not the owner"
        );
        _;
    }

  function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner]) {
      owner = msg.sender;
    }
  }

  function getContribution() public view returns (uint) {
    return contributions[msg.sender];
  }

  function withdraw() public onlyOwner {
    payable(owner).transfer(address(this).balance);
  }

  receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
  }
}
```

## 代码分析
合約的名稱為Fallback, 在初始合約的構造器中，我們可以知道owner的地址為合約的部署者，并且部署者的地址mapping指向一個叫做`contribution`的`uint`,值為1000 ether。在這關我們需要先獲得owner的權限，才能夠調用`withdraw()`函數，將合約中的餘額提取出來。那我們可以找尋一下有什麽辦法可以將owner變成我們的錢包地址。
首先在函數`contribute()`中，我們可以看到，儅我們的contribute值大於原來owner的時候，我們的地址便成爲了合約的owner。但是，由於目前owner的`contribution`是1000ether,這便意味著我們需要花費大量的以太去獲得owner的權限，這肯定不是我們想要的。所以我們得去尋找一個更好的方法。
在函數`receive()`中，我們看到儅`msg.value >0` 且 `msg.sender`的`contribution`大於0時，owner就會改變為`msg.sender`。所以我們只需要讓合約接受一個大於1 Wei的交易，并且利用`contribute()`函數，讓我們的地址的`contribution`大於0，就可以將owner的權限轉移給我們的地址了。在取得owner權限后，就可以使用`withdraw()`函數，完成本次的挑戰。

## 攻击过程
1. 調用`contribute()`函數，向合約支付1 Wei
2. 利用remix的low level interactions功能，調用`receive()`函數，向合約支付1 Wei，即可將owner權限轉移給我們的地址
3. 調用`withdraw()`函數，完成任務。