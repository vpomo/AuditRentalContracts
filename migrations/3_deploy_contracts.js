const BaseEscrowLib = artifacts.require('./BaseEscrowLib.sol')
const DateTime = artifacts.require('./DateTime.sol')
const ModerateEscrowLib = artifacts.require('./ModerateEscrowLib.sol')

module.exports = (deployer) => {
    deployer.deploy(DateTime);
    deployer.link(DateTime, BaseEscrowLib);
    deployer.deploy(BaseEscrowLib);

    deployer.link(DateTime, ModerateEscrowLib);
    deployer.link(BaseEscrowLib, ModerateEscrowLib);
    deployer.deploy(ModerateEscrowLib);
};
