// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Interfaces/IMessageHook.sol";
import "../Interfaces/IMailbox.sol";
import "../Interfaces/IInterchainGasPaymaster.sol";

contract NumSender {
    IMailbox public mailBox; // for fuji = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;
    uint32 counter = 0;
    address owner;
    uint32 chainID; // to mumbai = 80001
    IInterchainGasPaymaster igp; // for fuji = 0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a

    modifier onlyOWner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    constructor(address _mailBox, address _IInterchainGasPaymaster) {
        owner = msg.sender;
        mailBox = IMailbox(_mailBox);
        igp = IInterchainGasPaymaster(_IInterchainGasPaymaster);
    }

    function increaseCounter(
        uint32 _chainID,
        address _reci
    ) public payable onlyOWner {
        counter++;
        chainID = _chainID;
        uint gasAmount = 200000;
        bytes memory body = abi.encode(msg.sender, counter);
        bytes32 msgId = mailBox.dispatch(
            chainID,
            addressToBytes32(_reci),
            body
        );

        igp.payForGas{value: msg.value}(msgId, chainID, gasAmount, msg.sender);
    }

    function deacreaseCounter() public payable onlyOWner {
        counter--;
    }

    function getCounter() public view returns (uint) {
        return counter;
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
