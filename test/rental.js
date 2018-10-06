var StayBitContractFactory = artifacts.require("./StayBitContractFactory.sol");

var contractToken;


contract('StayBitContractFactory', (accounts) => {
    it('should deployed StayBitContractFactory', async ()  => {
        assert.equal(undefined, contractToken);
        contractToken = await StayBitContractFactory.deployed();
        assert.notEqual(undefined, contractToken);
    });

    it('get address StayBitContractFactory', async ()  => {
        assert.notEqual(undefined, contractToken.address);
    });
});