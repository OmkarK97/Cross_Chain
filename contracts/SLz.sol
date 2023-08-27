// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";

contract Num {
    uint public num;
    ILayerZeroEndpoint public endpoint;
    uint16 public destChain;

    constructor(address _endpoint) {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    function sendMessage(
        address remoteAddress,
        uint16 _destChain,
        string memory _message
    ) public payable {
        destChain = _destChain;
        bytes memory remoteAndLocalAddresses = abi.encodePacked(
            remoteAddress,
            address(this)
        );

        endpoint.send{value: msg.value}(
            destChain,
            remoteAndLocalAddresses,
            bytes(_message),
            payable(msg.sender),
            address(0x0),
            bytes("")
        );
    }
}
