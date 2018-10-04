const DateTime = artifacts.require('./DateTime.sol');

module.exports = (deployer) => {
    deployer.deploy(DateTime);

};
