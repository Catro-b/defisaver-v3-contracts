// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/uniswap/IUniswapV2Factory.sol";
import "../../interfaces/exchange/IUniswapRouter.sol";
import "../../utils/GasBurner.sol";
import "../../utils/TokenUtils.sol";
import "../ActionBase.sol";

/// @title Supplies liquidity to uniswap
contract UniSupply is ActionBase, TokenUtils, GasBurner {
    IUniswapRouter public constant router =
        IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IUniswapV2Factory public constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    struct UniSupplyData {
        address tokenA;
        address tokenB;
        address from;
        address to;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 deadline;
    }

    /// @inheritdoc ActionBase
    function executeAction(
        bytes[] memory _callData,
        bytes[] memory _subData,
        uint8[] memory _paramMapping,
        bytes32[] memory _returnValues
    ) public payable virtual override returns (bytes32) {
        UniSupplyData memory uniData = parseInputs(_callData);

        uniData.tokenA = _parseParamAddr(uniData.tokenA, _paramMapping[0], _subData, _returnValues);
        uniData.tokenB = _parseParamAddr(uniData.tokenB, _paramMapping[1], _subData, _returnValues);
        uniData.from = _parseParamAddr(uniData.from, _paramMapping[2], _subData, _returnValues);
        uniData.to = _parseParamAddr(uniData.to, _paramMapping[3], _subData, _returnValues);

        uint256 liqAmount = _uniSupply(uniData);

        return bytes32(liqAmount);
    }

    /// @inheritdoc ActionBase
    function executeActionDirect(bytes[] memory _callData) public payable override burnGas {
        UniSupplyData memory uniData = parseInputs(_callData);

        _uniSupply(uniData);
    }

    /// @inheritdoc ActionBase
    function actionType() public pure virtual override returns (uint8) {
        return uint8(ActionType.STANDARD_ACTION);
    }

    //////////////////////////// ACTION LOGIC ////////////////////////////

    /// @notice Adds liquiditu to uniswap and sends lp tokens and returns to _to
    /// @dev Uni markets can move, so extra tokens are expected to be left and are send to _to
    /// @param _uniData All the required data to deposit to uni
    function _uniSupply(UniSupplyData memory _uniData) internal returns (uint256) {
        // fetch tokens from the address
        pullTokens(_uniData.tokenA, _uniData.from, _uniData.amountADesired);
        pullTokens(_uniData.tokenB, _uniData.from, _uniData.amountBDesired);

        // handle if tokens are eth, convert to weth
        _uniData.tokenA = convertAndDepositToWeth(_uniData.tokenA, _uniData.amountADesired);
        _uniData.tokenB = convertAndDepositToWeth(_uniData.tokenB, _uniData.amountBDesired);

        // approve router so it can pull tokens
        approveToken(_uniData.tokenA, address(router), uint256(-1));
        approveToken(_uniData.tokenB, address(router), uint256(-1));

        // add liq. and get info how much we put in
        (uint amountA, uint amountB, uint liqAmount) = _addLiquidity(_uniData);

        // send leftovers
        withdrawTokens(_uniData.tokenA, _uniData.to, (_uniData.amountADesired - amountA));
        withdrawTokens(_uniData.tokenB, _uniData.to, (_uniData.amountBDesired - amountB));

        return liqAmount;
    }

    function _addLiquidity(UniSupplyData memory _uniData)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liqAmount
        )
    {
        (amountA, amountB, liqAmount) = router.addLiquidity(
            _uniData.tokenA,
            _uniData.tokenB,
            _uniData.amountADesired,
            _uniData.amountBDesired,
            _uniData.amountAMin,
            _uniData.amountBMin,
            _uniData.to,
            _uniData.deadline
        );
    }

    function parseInputs(bytes[] memory _callData)
        internal
        pure
        returns (UniSupplyData memory uniData)
    {
        uniData = abi.decode(_callData[0], (UniSupplyData));
    }
}