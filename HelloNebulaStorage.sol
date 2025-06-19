// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract HelloNebulaStorage {
    string public message;

    function setMessage(string calldata _message) external {
        message = _message;
    }

    function getMessage() external view returns (string memory) {
        return message;
    }
}
