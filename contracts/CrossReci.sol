// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/IStargateReceiver.sol";

contract CrossReci is NonblockingLzApp {
    IERC20 public token;
    uint256 dstChainID;
    uint public reci;
    ILayerZeroEndpoint public endpoint;
    IERC20 public usdt;
    IUniswapV2Router02 public uniswap;
    IStargateRouter public starGate;

    constructor(
        address _token,
        address _usdt,
        address _uniswap,
        address _starGate,
        address _endPoint
    ) NonblockingLzApp(_endPoint) {
        token = IERC20(_token);
        usdt = IERC20(_usdt);
        endpoint = ILayerZeroEndpoint(_endPoint);
        uniswap = IUniswapV2Router02(_uniswap);
        starGate = IStargateRouter(_starGate);
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        // The LayerZero _payload (message) is decoded as a uint and stored in the "data" variable.
        reci = abi.decode(_payload, (uint));
        if (reci == 1) {
            deployLiqui();
        } else {
            withdrawLqiui(20, address(this));
        }
    }

    function deployLiqui() internal {
        uint amountUSDCD = token.balanceOf(address(this));
        uint amountUSDTD = usdt.balanceOf(address(this));
        uint amountUSDCMin;
        uint amountUSDTMin;
        address to = address(this);
        uint deadline;

        token.approve(address(uniswap), 100000000);
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
    }

    function withdrawLqiui(uint _amount, address _reci) internal {
        withdrawUni(_amount);
        uint fees;
        starGate.swap{value: fees}(
            10132, // To Optimism Goerli
            1, // pool id for sending Usdc on source chain
            1, //pool id for receiving Usdc on destination chain
            payable(address(this)), //address to get  extra fees refund
            _amount,
            0,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            abi.encodePacked(_reci), // receiver address
            bytes("")
        );
    }

    function withdrawUni(uint _amount) internal {
        uint minUsdc;
        uint minUsdt;
        uint deadline;
        token.approve(address(uniswap), _amount);
        uniswap.removeLiquidity(
            address(token),
            address(usdt),
            _amount,
            minUsdc,
            minUsdt,
            address(this),
            deadline
        );
    }
}
