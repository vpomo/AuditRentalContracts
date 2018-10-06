const BaseEscrowLib = artifacts.require('./BaseEscrowLib.sol')
const DateTime = artifacts.require('./DateTime.sol')
const FlexibleEscrowLib = artifacts.require('./FlexibleEscrowLib.sol')

module.exports = (deployer) => {
    deployer.deploy(DateTime);
    deployer.link(DateTime, BaseEscrowLib);
    deployer.deploy(BaseEscrowLib);

    deployer.link(DateTime, FlexibleEscrowLib);
    deployer.link(BaseEscrowLib, FlexibleEscrowLib);
    deployer.deploy(FlexibleEscrowLib);
};
