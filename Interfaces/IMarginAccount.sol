// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarginAccount {
    function updateFundingFee(
        address _user,
        address _indexToken,
        int256 _fundingFee
    ) external returns (uint256);

    function lockFunds(address _user, address _indexToken) external;

    function unlockFunds(address _user, address _indexToken) external;

    function deposit(
        uint256 _amount,
        address _indexToken,
        address _user
    ) external;

    function withdraw(
        uint256 _amount,
        address _indexToken,
        uint32 _destination
    ) external;

    function balances(bytes32 _id) external returns (uint256);
}
