const MyToken = artifacts.require('./MyToken.sol')
const BaseEscrowLib = artifacts.require('./BaseEscrowLib.sol')
const DateTime = artifacts.require('./DateTime.sol')
const ModerateEscrowLib = artifacts.require('./ModerateEscrowLib.sol')
const Ownable = artifacts.require('./Ownable.sol')
const FlexibleEscrowLib = artifacts.require('./FlexibleEscrowLib.sol')
const StrictEscrowLib = artifacts.require('./StrictEscrowLib.sol')
const StayBitContractFactory = artifacts.require('./StayBitContractFactory.sol')

module.exports = (deployer) => {
    deployer.deploy(DateTime);
    deployer.link(DateTime, BaseEscrowLib);
    deployer.deploy(BaseEscrowLib);

    deployer.link(DateTime, FlexibleEscrowLib);
    deployer.link(BaseEscrowLib, FlexibleEscrowLib);
    deployer.deploy(FlexibleEscrowLib);

    deployer.link(DateTime, ModerateEscrowLib);
    deployer.link(BaseEscrowLib, ModerateEscrowLib);
    deployer.deploy(ModerateEscrowLib);

    deployer.deploy(Ownable);
    deployer.deploy(MyToken);

    deployer.link(DateTime, StrictEscrowLib);
    deployer.link(BaseEscrowLib, StrictEscrowLib);
    deployer.deploy(StrictEscrowLib);

    deployer.link(BaseEscrowLib, StayBitContractFactory);
    deployer.link(FlexibleEscrowLib, StayBitContractFactory);
    deployer.link(ModerateEscrowLib, StayBitContractFactory);
    deployer.link(StrictEscrowLib, StayBitContractFactory);
    deployer.link(Ownable, StayBitContractFactory);

    deployer.deploy(StayBitContractFactory);
};
