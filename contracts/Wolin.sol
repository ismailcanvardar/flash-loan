// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./IKyberNetworkProxy.sol";
import "./IUniswapV2Router02.sol";
import { FlashLoanReceiverBase } from "./FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider } from "./Interfaces.sol";
import { SafeMath } from "./Libraries.sol";

contract Wolin is FlashLoanReceiverBase {
    address owner;
    IKyberNetworkProxy kyberNetworkProxy;
    IUniswapV2Router02 uniswapRouter;
    /*address payable public platformWallet;*/
    uint256 public platformFeeBps;
    uint deadline;
    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    using SafeMath for uint256;

    constructor (ILendingPoolAddressesProvider _addressProvider, IKyberNetworkProxy _kyberNetworkProxyProvider, IUniswapV2Router02 _uniswapRouterProvider,/* address payable _platformWallet,*/ uint256 _platformFeeBps) 
    FlashLoanReceiverBase(_addressProvider) public {
        owner = msg.sender;
        kyberNetworkProxy = _kyberNetworkProxyProvider;
        uniswapRouter = _uniswapRouterProvider;
        platformFeeBps = _platformFeeBps;
        // setting deadline to avoid scenario where miners hang onto it and execute at a more profitable time
        deadline = block.timestamp + 300; // 5 minutes
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner can call this function.");
        _;
    }

    function getConversionRatesFromKyberNetwork(
        IERC20 srcToken,
        IERC20 destToken,
        uint256 srcQty
    ) public
      view
      returns (uint256)
    {
      return kyberNetworkProxy.getExpectedRateAfterFee(srcToken, destToken, srcQty, platformFeeBps, '');
    }

    function executeSwapInKyberNetwork(
        IERC20 srcToken,
        uint256 srcQty,
        IERC20 destToken,
        //address payable destAddress,
        uint256 maxDestAmount
    ) external payable returns(uint) {
        if (srcToken != ETH_TOKEN_ADDRESS) {
            require(srcToken.approve(address(kyberNetworkProxy), srcQty), "approval to srcQty failed");
        }

        // Get the minimum conversion rate
        uint256 minConversionRate = getConversionRatesFromKyberNetwork(srcToken, destToken, srcQty);

        // Execute the trade and send to destAddress
        uint actualDestAmount = kyberNetworkProxy.tradeWithHintAndFee{value: msg.value}(
            srcToken,
            srcQty,
            destToken,
            payable(address(this)),
            maxDestAmount,
            minConversionRate,
            payable(address(this)),
            platformFeeBps,
            '' // empty hint
        );

        return actualDestAmount * (10**6);
    }

    function getPairRateFromUniswap(
        uint amountIn, address[] memory path
    ) public
      view
      returns (uint[] memory amounts)
    {
      return uniswapRouter.getAmountsOut(amountIn, path);
    }
    
    /// @dev Swap from srcToken to destToken (including ether)
    function executeSwapInUniswap(
        uint amountIn,
        address[] calldata path
        // address to,
    ) external payable returns(uint) {
        require(IERC20(path[0]).approve(address(uniswapRouter), amountIn), 'approve failed.');

        uint[] memory amountOut = getPairRateFromUniswap(amountIn, path);

        uint[] memory actualAmounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOut[1],
            path,
            address(this),
            deadline
        );

        return actualAmounts[1];
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        string memory condition = string(params);
        
        if (keccak256(abi.encodePacked((condition))) == keccak256(abi.encodePacked(("condition1")))) {
            
        } else if (keccak256(abi.encodePacked((condition))) == keccak256(abi.encodePacked(("condition1")))) {
            
        }

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function myFlashLoanCall(address[] memory assets, uint256[] memory amounts, uint256[] memory modes, bytes memory params) public {
        address receiverAddress = address(this);
        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
}