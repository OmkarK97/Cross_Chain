// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "../Interfaces/IMarginAccount.sol";
import "../Interfaces/IMessageRecipient.sol";

contract NumReci is IMessageRecipient {
    address owner;
    address mailBox;
    address srcContract;

    modifier onlyAuth() {
        require(msg.sender == mailBox || msg.sender == owner);
        _;
    }

    function setSrcContract(address _srcContract) public onlyAuth {
        srcContract = _srcContract;
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external override onlyAuth {
        require(
            bytes32ToAddress(_sender) == srcContract,
            "You are not Authorized to send"
        );
    }

    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}
