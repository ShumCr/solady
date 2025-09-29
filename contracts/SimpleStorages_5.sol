// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SimpleStorage - tiny example contract
/// @notice Stores a single uint256 and emits an event on change
contract SimpleStorage {
    uint256 public value;
    event ValueChanged(uint256 indexed newValue, address indexed changedBy);

    /// @notice Set a new value
    /// @param _value new value to store
    function set(uint256 _value) external {
        value = _value;
        emit ValueChanged(_value, msg.sender);
    }
}
