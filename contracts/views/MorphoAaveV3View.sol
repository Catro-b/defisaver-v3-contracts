// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../actions/morpho/aaveV3/helpers/MorphoAaveV3Helper.sol";

contract MorphoAaveV2View is MorphoAaveV3Helper {

    struct UserInfo {
        uint256 userHealthFactor;
        uint256 morphoClaimed;
        UserBalance[] userBalances;
    }

    struct UserBalance {
        address market;
        address underlying;
        uint8 decimals;
        uint256 userSupplyRate;
        uint256 userBorrowRate;
        uint256 supplyBalance;
        uint256 borrowBalance;
        uint256 collateralBalance;
    }

    struct MarketInfo {
        address market; // aToken
        address underlying;
        uint8 decimals;
        uint256 p2pSupplyAmount;
        uint256 poolSupplyAmount;
        uint256 p2pBorrowAmount;
        uint256 poolBorrowAmount;
        uint256 p2pSupplyRate;
        uint256 p2pBorrowRate;
        uint256 poolSupplyRate;
        uint256 poolBorrowRate;
        uint256 reserveFactor;
        Types.PauseStatuses pauseStatus;
    }

    function getUserInfo(address _morphoAddr, address _userAddr) external view returns (
        UserInfo memory userInfo
    ) {
        IMorphoAaveV3 morpho = IMorphoAaveV3(_morphoAddr);

        address[] memory allMarkets = morpho.marketsCreated();

        uint256 safetyRatio = getSafetyRatio(_morphoAddr, _userAddr);

        userInfo = UserInfo({
            userHealthFactor: safetyRatio,
            morphoClaimed: 0,
            userBalances: new UserBalance[](allMarkets.length)
        });

        for(uint256 i = 0; i < allMarkets.length; ++i) {

            Types.Market memory marketData = morpho.market(allMarkets[i]);

             userInfo.userBalances[i] = UserBalance({
                market: allMarkets[i],
                underlying: marketData.underlying,
                decimals: uint8(IERC20(marketData.underlying).decimals()),
                userSupplyRate: 0,
                userBorrowRate: 0,
                supplyBalance: morpho.supplyBalance(marketData.underlying, _userAddr),
                borrowBalance: morpho.borrowBalance(marketData.underlying, _userAddr),
                collateralBalance: morpho.collateralBalance(marketData.underlying, _userAddr)
             });
        }

    }

    function getMarketInfo(address _morphoAddr, address _market) public view returns (MarketInfo memory) {
        IMorphoAaveV3 morpho = IMorphoAaveV3(_morphoAddr);

        Types.Market memory marketData = morpho.market(_market);

        Types.Indexes256 memory updatedIndexes = morpho.updatedIndexes(marketData.underlying);

        uint256 proportionIdle = marketData.idleSupply; 
        if (proportionIdle > 0) {
            proportionIdle = min( 
                RAY,
                rdiv(
                    marketData.idleSupply,
                    rmul(marketData.deltas.supply.scaledP2PTotal, updatedIndexes.supply.p2pIndex)
                )
            );
        }

        uint256 supplyProportionDelta = marketData.idleSupply;
        if (supplyProportionDelta > 0) {
            supplyProportionDelta = min(
                RAY - proportionIdle,
                rdiv(
                    rmul(marketData.deltas.supply.scaledDelta, updatedIndexes.supply.poolIndex),
                    rmul(marketData.deltas.supply.scaledP2PTotal, updatedIndexes.supply.p2pIndex)
                )
            );
        }

        uint256 borrowProportionDelta = marketData.idleSupply;
        if (borrowProportionDelta > 0) {
            borrowProportionDelta = min(
                RAY,
                rdiv(
                    rmul(marketData.deltas.borrow.scaledDelta, updatedIndexes.borrow.poolIndex),
                    rmul(marketData.deltas.borrow.scaledP2PTotal, updatedIndexes.borrow.p2pIndex)
                )
            );
        }

        uint256 morphoBorrowInP2P = rmul(updatedIndexes.borrow.p2pIndex, marketData.deltas.borrow.scaledP2PTotal);
        

        // return MarketInfo({
        //     market: _market,
        //     underlying: marketData.underlying,
        //     decimals: uint8(IERC20(marketData.underlying).decimals()),
        //     p2pSupplyAmount: p2pSupplyAmount,
        //     poolSupplyAmount: poolSupplyAmount,
        //     p2pBorrowAmount: p2pBorrowAmount,
        //     poolBorrowAmount: poolBorrowAmount,
        //     p2pSupplyRate: p2pSupplyRate,
        //     p2pBorrowRate: p2pBorrowRate,
        //     poolSupplyRate: poolSupplyRate,
        //     poolBorrowRate: poolBorrowRate,
        //     reserveFactor: marketData.reserveFactor,
        //     pauseStatus: marketData.pauseStatuses
        // });
    }


    function getAllMarkets(address _morphoAddr) external view returns (address[] memory) {
        return IMorphoAaveV3(_morphoAddr).marketsCreated();
    }
}
