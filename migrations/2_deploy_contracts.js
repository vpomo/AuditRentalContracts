const PHICrowdsale = artifacts.require('./PHICrowdsale.sol');

module.exports = (deployer) => {
    //http://www.onlineconversion.com/unix_time.htm
    var owner =  "0x6a108Cf23b06b5349893ECDE2203c7cE6dc745E0";
    var wallet = "0xab8936D04e69bF5CAD660B3448458a8Ed4A54935";

    deployer.deploy(PHICrowdsale, owner, wallet);

};
