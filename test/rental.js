var StayBitContractFactory = artifacts.require("./StayBitContractFactory.sol");
var MyToken = artifacts.require("./MyToken.sol");

var contractFactoty;
var contractToken;

contract('StayBitContractFactory', (accounts) => {
    it('should deployed StayBitContractFactory', async ()  => {
        assert.equal(undefined, contractFactoty);
        contractFactoty = await StayBitContractFactory.deployed();
        assert.notEqual(undefined, contractFactoty);
    });

    it('get address StayBitContractFactory', async ()  => {
        assert.notEqual(undefined, contractFactoty.address);
    });
});

contract('MyToken', (accounts) => {
    it('should deployed MyToken', async ()  => {
        assert.equal(undefined, contractToken);
        contractToken = await MyToken.deployed();
        assert.notEqual(undefined, contractToken);
    });

    it('get address MyToken', async ()  => {
        assert.notEqual(undefined, contractToken.address);
        var balanceOwner = await contractToken.balanceOf.call(accounts[0]);
        //console.log("balanceOwner", Number(balanceOwner));
        assert.equal(1e24, Number(balanceOwner));

        await contractToken.faucetWithdrawToken(1e21, {from:accounts[1]});
        var balanceAccountOne = await contractToken.balanceOf.call(accounts[1]);
        assert.equal(1e21, Number(balanceAccountOne));
        //console.log("balanceAccountOne", Number(balanceAccountOne));
        await contractToken.faucetWithdrawToken(1e21, {from:accounts[1]});
        //await contractToken.faucetWithdrawToken(1e21, {from:accounts[1]});

    });

    it('set address MyTokenContract to contractFactoty', async ()  => {
        //function SetTokenInfo(uint tokenId, address tokenAddress, uint rentMin, uint rentMax)
        await contractFactoty.SetTokenInfo(1, contractToken.address, 30, 70);
    });

    it('set factory params to contractFactoty', async ()  => {
        await contractFactoty.SetFactoryParams(true, true, 10);
        var feeBalance = await contractFactoty.GetFeeBalance.call(1);
        console.log("feeBalance", Number(feeBalance));

        var aaaa = await contractFactoty.CreateContract.call(45, 1, 1539561600, 1544400000, 100, "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db",
                                            "lock data", 1, 1, "GUID", 100, {from:accounts[1]});
        // 1539561600 - Mon, 15 Oct 2018
        // 1544400000 - Mon, 10 Dec 2018
        // extraAmount = 100
        // 	_TotalAmount = 2620
        // CalculateCreateFee(uint(contracts[keccak256(Guid)]._TotalAmount)) = 262

//                       75,             1,          1533417601,          1534281601,      100,       "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "", "0x4514d8d91a10bda73c10e2b8ffd99cb9646620a9", 1, "test"
//CreateContract(int rentPerDay, int cancelPolicy, uint moveInDate, uint moveOutDate, int secDeposit, address landlord, string doorLockData, uint tokenId, int Id, string Guid, uint extraAmount) public
        console.log("aaa = ", Number(aaaa));
});

});

