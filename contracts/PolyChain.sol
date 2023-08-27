// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../node_modules/@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";
import "../node_modules/@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol";

contract reciChain is NonblockingLzApp {
    uint16 public destChain; // of fuji 10106
    IERC20 public token; //of polygon 0x742DfA5Aa70a8212857966D491D67B09Ce7D6ec7
    ILayerZeroEndpoint endP; // of polygon 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8
    IStargateRouter public starGate; //  of polygon 0x817436a076060D158204d955E5403b6Ed0A5fac0
    address public user;
    uint public value;
    uint8 public deci;
    mapping(address => uint) public balance;
    uint fees = 40000000000000000;

    constructor(
        address _lzEndPoint,
        uint16 _dstC,
        address _token,
        address _starGate
    ) NonblockingLzApp(_lzEndPoint) {
        destChain = _dstC;
        endP = ILayerZeroEndpoint(_lzEndPoint);
        token = IERC20(_token);
        starGate = IStargateRouter(_starGate);
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        (user, value, deci) = abi.decode(_payload, (address, uint256, uint8));
        if (deci == 1) {
            balance[user] += value;
        } else {
            balance[user] -= value;
            withD(user, value);
        }
    }

    function withD(address _reci, uint _amount) internal {
        token.approve(address(starGate), _amount);
        starGate.swap{value: address(this).balance}(
            destChain,
            1,
            1,
            payable(address(this)),
            _amount,
            0,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            abi.encodePacked(_reci),
            bytes("")
        );
    }

    receive() external payable {}

    function withdrawAvax() public {
        address payable recipient = payable(msg.sender);
        (bool sent, ) = recipient.call{value: (address(this).balance)}("");
    }
}
