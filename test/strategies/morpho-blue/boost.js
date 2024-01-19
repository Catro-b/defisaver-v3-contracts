const { resetForkToBlock } = require('../../utils');
const { morphoBlueBoostStrategyTest } = require('./morphoblue-tests');

describe('MorphoBlue Boost Strategy test', function () {
    this.timeout(80000);

    it('... test MorphoBlue boost strategy', async () => {
        await resetForkToBlock();
        await morphoBlueBoostStrategyTest();
    }).timeout(50000);
});
