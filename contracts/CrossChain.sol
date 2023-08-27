// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
// chain id base =10160

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract CrossChain is NonblockingLzApp {
    IERC20 public token; // optimism goerli usdc address = 0x0CEDBAF2D0bFF895C861c5422544090EEdC653Bf
    IERC20 public usdt;
    string public reci;
    uint16 public chainID;
    uint256 public send;
    uint256 public withD;
    IUniswapV2Router02 public uniswap;
    ILayerZeroEndpoint public endpoint;

    IStargateRouter public starGate; // op goerli stargate router address = 0x95461eF0e0ecabC049a5c4a6B98Ca7B335FAF068

    mapping(address => uint) public balances;

    constructor(
        address _token,
        address _router,
        address _uniswap,
        address _usdt,
        address _endPoint
    ) NonblockingLzApp(_endPoint) {
        send = 1;
        withD = 2;
        token = IERC20(_token);
        usdt = IERC20(_usdt);
        endpoint = ILayerZeroEndpoint(_endPoint);
        starGate = IStargateRouter(_router);
        uniswap = IUniswapV2Router02(_uniswap);
    }

    function addTokens(uint256 _amount) public payable {
        uint256 fLiqui = _amount / 2;
        uint256 bLiqui = fLiqui; // bLiqui is liquidity to be bridged
        uint256 minAmount = fLiqui - (1 * 10 ** 6);
        token.transferFrom(msg.sender, address(this), _amount); // From user to contract
        balances[msg.sender] = _amount;
        uint amountUSDCD;
        uint amountUSDTD;
        uint amountUSDCMin;
        uint amountUSDTMin;
        address to = address(this);
        uint deadline;
        token.approve(address(starGate), 1000000000000000); //For contract to router
        starGate.swap{value: msg.value}(
            10106, // To Base Goerli Testnet
            1, // pool id for sending Usdc on source chain
            1, // pool id for receiving Usdc on destination chain
            payable(msg.sender), // address to get extra fees refund
            bLiqui,
            minAmount,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            abi.encodePacked(msg.sender), // receiver address
            bytes("")
        );
        token.approve(address(uniswap), fLiqui); // Router allowence for usdc and usdt transfer
        uniswap.addLiquidity(
            address(token),
            address(usdt),
            amountUSDCD,
            amountUSDTD,
            amountUSDCMin,
            amountUSDTMin,
            to,
            deadline
        );
        bytes memory payload = abi.encode(send);
        _lzSend(
            chainID,
            payload,
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
    }

    function withdrawTokens(uint256 _amount) public payable {
        require(
            _amount <= balances[msg.sender] &&
                balances[msg.sender] - _amount >= 0,
            "You dont have enough balance"
        );
        balances[msg.sender] = balances[msg.sender] - _amount; // update the balance
        uint minUsdc;
        uint minUsdt;
        uint deadline;
        token.approve(address(uniswap), _amount / 2);
        uniswap.removeLiquidity(
            address(token),
            address(usdt),
            _amount / 2,
            minUsdc,
            minUsdt,
            msg.sender,
            deadline
        );
        bytes memory payload = abi.encode(reci);
        _lzSend(
            chainID,
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
}
