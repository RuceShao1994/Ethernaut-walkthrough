# Naught Coin
Naught Coin要求我們將還未解鎖的代幣轉出，考察了函數重寫以及ERC20的一些知識，讓我們看一下代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'openzeppelin-contracts-08/token/ERC20/ERC20.sol';

 contract NaughtCoin is ERC20 {

  // string public constant name = 'NaughtCoin';
  // string public constant symbol = '0x0';
  // uint public constant decimals = 18;
  uint public timeLock = block.timestamp + 10 * 365 days;
  uint256 public INITIAL_SUPPLY;
  address public player;

  constructor(address _player) 
  ERC20('NaughtCoin', '0x0') {
    player = _player;
    INITIAL_SUPPLY = 1000000 * (10**uint256(decimals()));
    // _totalSupply = INITIAL_SUPPLY;
    // _balances[player] = INITIAL_SUPPLY;
    _mint(player, INITIAL_SUPPLY);
    emit Transfer(address(0), player, INITIAL_SUPPLY);
  }
  
  function transfer(address _to, uint256 _value) override public lockTokens returns(bool) {
    super.transfer(_to, _value);
  }

  // Prevent the initial owner from transferring tokens until the timelock has passed
  modifier lockTokens() {
    if (msg.sender == player) {
      require(block.timestamp > timeLock);
      _;
    } else {
     _;
    }
  } 
} 
```
## 代碼分析
要成功通過這一關，我們需要將player手中的NaugtCoin轉移到其他的地址。但是在合約中我們發現，transfer被增加了一個modifier，儅msg.sender是player時，需要儅block的時間戳大於timelock的時間才能調用被這個modifier修飾的函數。而這個timelock的時間是10年，我們不可能等那麽久的時間再進行通關。
但是對與ERC20的合約瞭解的同學發現，NaughtCoin繼承了ERC20，但是它只override了transfer函數，并沒有override approve和transferFrom函數，這就意味著我們可以調用父合約的approve和transferFrom函數來轉移代幣。

## 攻擊過程
1. 使用console, 使用approve函數將player手中的所有的代幣數額授權。
2. 使用transferFrom函數將代幣轉出，完成任務。


