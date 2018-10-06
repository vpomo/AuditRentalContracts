const BaseEscrowLib = artifacts.require('./BaseEscrowLib.sol')
const DateTime = artifacts.require('./DateTime.sol')
const StrictEscrowLib = artifacts.require('./StrictEscrowLib.sol')

module.exports = (deployer) => {
    deployer.deploy(DateTime);
    deployer.link(DateTime, BaseEscrowLib);
    deployer.deploy(BaseEscrowLib);

    deployer.link(DateTime, StrictEscrowLib);
    deployer.link(BaseEscrowLib, StrictEscrowLib);
    deployer.deploy(StrictEscrowLib);
};
