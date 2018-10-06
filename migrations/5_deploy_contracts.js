const BaseEscrowLib = artifacts.require('./BaseEscrowLib.sol')
const DateTime = artifacts.require('./DateTime.sol')
const Ownable = artifacts.require('./Ownable.sol')
const StayBitContractFactory = artifacts.require('./StayBitContractFactory.sol')

module.exports = (deployer) => {
    deployer.deploy(DateTime);
    deployer.link(DateTime, BaseEscrowLib);
    deployer.deploy(BaseEscrowLib);

    deployer.deploy(Ownable);

    deployer.link(BaseEscrowLib, StayBitContractFactory);
    deployer.link(Ownable, StayBitContractFactory);

    deployer.deploy(StayBitContractFactory);
};
