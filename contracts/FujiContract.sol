// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../node_modules/@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";
import "../node_modules/@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol";

contract MainChain is NonblockingLzApp {
    uint16 public destChain; //  of polygon 10109
    IERC20 public token; // of fuji 0x4A0D1092E9df255cf95D72834Ea9255132782318
    ILayerZeroEndpoint endP; // fuji endpoint 0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706
    IStargateRouter public starGate; //of fuji 0x13093E05Eb890dfA6DacecBdE51d24DabAb2Faa1
    string public reci;
    uint8 public send;
    uint8 public reciv;
    address reciAddress;
    uint256 fess = 500000;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public avaxBalance;
    mapping(address => uint256) public baseBalance;

    constructor(
        address _token,
        address _endpoint,
        address _starGate,
        uint16 _dstChain,
        address _reciAddress
    ) NonblockingLzApp(_endpoint) {
        token = IERC20(_token);
        starGate = IStargateRouter(_starGate);
        endP = ILayerZeroEndpoint(_endpoint);
        destChain = _dstChain;
        send = 1;
        reciv = 2;
        reciAddress = _reciAddress;
    }

    function sendVal(uint256 _amount) public payable {
        uint sAmount = _amount - fess;
        uint transferB = _amount / 2;
        balance[msg.sender] = sAmount;
        avaxBalance[msg.sender] = sAmount / 2;
        baseBalance[msg.sender] = sAmount / 2;

        token.transferFrom(msg.sender, address(this), _amount);
        token.approve(address(starGate), _amount);
        bytes memory payload = abi.encode(msg.sender, sAmount / 2, send);

        starGate.swap{value: msg.value}(
            destChain,
            1,
            1,
            payable(msg.sender),
            transferB,
            0,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            abi.encodePacked(reciAddress),
            bytes("")
        );

        _lzSend(
            destChain,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes(""),
            address(this).balance
        );
    }

    function WithD(uint256 _amount) public payable {
        require(balance[msg.sender] >= _amount);
        balance[msg.sender] = balance[msg.sender] - _amount;
        avaxBalance[msg.sender] = avaxBalance[msg.sender] - _amount / 2;
        baseBalance[msg.sender] = baseBalance[msg.sender] - _amount / 2;
        token.transfer(msg.sender, _amount / 2);
        bytes memory payload = abi.encode(msg.sender, _amount / 2, reciv);
        _lzSend(
            destChain,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        // The LayerZero _payload (message) is decoded as a string and stored in the "data" variable.
        reci = abi.decode(_payload, (string));
    }

    function withdrawAvax() public {
        address payable recipient = payable(msg.sender);
        (bool sent, ) = recipient.call{value: (address(this).balance)}("");
    }

    receive() external payable {}
}

//deployed address on fuji 0x50d4072d58498f56B2816e4EEAbfdf811701b9e2
