// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Interfaces/ILayerZeroReceiver.sol";

contract RLz is ILayerZeroReceiver {
    string public msg;

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external override {
        msg = abi.decode(_payload, (string));
    }

    function getMsg() public view returns (string memory) {
        return msg;
    }
}
