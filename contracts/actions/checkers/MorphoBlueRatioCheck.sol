// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "../ActionBase.sol";
import "../../actions/morpho-blue/helpers/MorphoBlueHelper.sol";
import "../../utils/TransientStorage.sol";

contract MorphoBlueRatioCheck is ActionBase, MorphoBlueHelper {

    /// @dev 5% offset acceptable
    uint256 internal constant RATIO_OFFSET = 50000000000000000;

    TransientStorage public constant tempStorage = TransientStorage(TRANSIENT_STORAGE);

    error BadAfterRatio(uint256 startRatio, uint256 currRatio);

    enum RatioState {
        IN_BOOST,
        IN_REPAY
    }

    struct Params {
        MarketParams marketParams;
        address user;
        RatioState ratioState;
        uint256 targetRatio;
    }

    /// @inheritdoc ActionBase
    function executeAction(
        bytes memory _callData,
        bytes32[] memory _subData,
        uint8[] memory _paramMapping,
        bytes32[] memory _returnValues
    ) public payable virtual override returns (bytes32) {
        Params memory inputData = parseInputs(_callData);

        inputData.marketParams.loanToken = _parseParamAddr(inputData.marketParams.loanToken , _paramMapping[0], _subData, _returnValues);
        inputData.marketParams.collateralToken = _parseParamAddr(inputData.marketParams.collateralToken , _paramMapping[1], _subData, _returnValues);
        inputData.marketParams.oracle = _parseParamAddr(inputData.marketParams.oracle , _paramMapping[2], _subData, _returnValues);
        inputData.marketParams.irm = _parseParamAddr(inputData.marketParams.irm , _paramMapping[3], _subData, _returnValues);
        inputData.marketParams.lltv = _parseParamUint(inputData.marketParams.lltv, _paramMapping[4], _subData, _returnValues);
        address user = _parseParamAddr(address(inputData.user), _paramMapping[5], _subData, _returnValues);
        uint256 ratioState = _parseParamUint(uint256(inputData.ratioState), _paramMapping[6], _subData, _returnValues);
        uint256 targetRatio = _parseParamUint(uint256(inputData.targetRatio), _paramMapping[7], _subData, _returnValues);

        uint256 currRatio = getRatioUsingParams(inputData.marketParams, user);

        uint256 startRatio = uint256(tempStorage.getBytes32("MORPHOBLUE_RATIO"));
        
        // if we are doing repay
        if (RatioState(ratioState) == RatioState.IN_REPAY) {
            // if repay ratio should be better off
            if (currRatio <= startRatio) {
                revert BadAfterRatio(startRatio, currRatio);
            }

            // can't repay too much over targetRatio so we don't trigger boost after
            if (currRatio > (targetRatio + RATIO_OFFSET)) {
                revert BadAfterRatio(startRatio, currRatio);
            }
        }

        // if we are doing boost
        if (RatioState(ratioState) == RatioState.IN_BOOST) {
            // if boost ratio should be less
            if (currRatio >= startRatio) {
                revert BadAfterRatio(startRatio, currRatio);
            }

            // can't boost too much under targetRatio so we don't trigger repay after
            if (currRatio < (targetRatio - RATIO_OFFSET)) {
                revert BadAfterRatio(startRatio, currRatio);
            }
        }

        emit ActionEvent("MorphoBlueRatioCheck", abi.encode(currRatio));
        return bytes32(currRatio);
    }

    /// @inheritdoc ActionBase
    // solhint-disable-next-line no-empty-blocks
    function executeActionDirect(bytes memory _callData) public payable override {}

    /// @inheritdoc ActionBase
    function actionType() public pure virtual override returns (uint8) {
        return uint8(ActionType.CHECK_ACTION);
    }

    function parseInputs(bytes memory _callData) public pure returns (Params memory inputData) {
        inputData = abi.decode(_callData, (Params));
    }

}
