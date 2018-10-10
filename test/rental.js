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
    var addressLandlord = accounts[2];
    var guid = "23fff-fhgjg";

    var guidTestTenant = "23fff-tenant";
    var guidTestLandlord = "23fff-landlord";

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
        await contractToken.approve(contractFactoty.address, 1e21, {from:accounts[1]});

    });

    it('set address MyTokenContract to contractFactoty', async ()  => {
        //function SetTokenInfo(uint tokenId, address tokenAddress, uint rentMin, uint rentMax)
        await contractFactoty.SetTokenInfo(1, contractToken.address, 30, 70);
    });

    it('set factory params and create contractFactory', async ()  => {
        await contractFactoty.SetFactoryParams(true, true, 10);
        await contractFactoty.CreateContract(45, 1, 1539561600, 1539993600, 10,
        addressLandlord, "lock data", 1, 1, guid, 100, {from:accounts[1]});
    });

    it('test status terminate contract by Tenant', async ()  => {
        await contractFactoty.CreateContract(45, 1, 1539561600, 1539993600, 10,
            addressLandlord, "lock data", 1, 1, guidTestTenant, 100, {from:accounts[1]});
        /*
        curDate = contracts[keccak256(Guid)].GetCurrentDate();
        escrState = contracts[keccak256(Guid)]._State;
        escrStage = contracts[keccak256(Guid)].GetCurrentStage();
        tenantMovedIn = contracts[keccak256(Guid)]._TenantConfirmedMoveIn;
        actualBalance = contracts[keccak256(Guid)].GetContractBalance();
        misrepSignaled = contracts[keccak256(Guid)]._MisrepSignaled;
        doorLockData = contracts[keccak256(Guid)]._DoorLockData;
        calcAmount = contracts[keccak256(Guid)]._TotalAmount;
        actualMoveOutDate = contracts[keccak256(Guid)]._ActualMoveOutDate;
        cancelPolicy = contracts[keccak256(Guid)]._CancelPolicy;
        */
        //await contractFactoty.TenantTerminate(guid);
        var jsonContractInfo = await contractFactoty.GetContractInfo(guidTestTenant);
        //["1539200057","1","0",false,"335",false,"lock data","235","0","1"]
        console.log("Before", JSON.stringify(jsonContractInfo));
        assert.equal(1, jsonContractInfo[1]);
        assert.equal(0, jsonContractInfo[2]);

         // var balanceTenant = await contractToken.balanceOf.call(accounts[1]);
         // console.log("Before balance Tenant", Number(balanceTenant));
         // var balanceLandlord = await contractToken.balanceOf.call(accounts[2]);
         // console.log("Before balance Landlord", Number(balanceLandlord));


        await contractFactoty.TenantTerminate(guidTestTenant, {from:accounts[1]});
        jsonContractInfo = await contractFactoty.GetContractInfo(guidTestTenant);
        assert.equal(2, jsonContractInfo[1]);
        console.log("After", JSON.stringify(jsonContractInfo));

          balanceTenant = await contractToken.balanceOf.call(accounts[1]);
          console.log("After balance Tenant", Number(balanceTenant));
         // balanceLandlord = await contractToken.balanceOf.call(accounts[2]);
         // console.log("After balance Landlord", Number(balanceLandlord));
    });

    it('test status terminate contract by Landlord', async ()  => {
        await contractFactoty.CreateContract(45, 1, 1539561600, 1539993600, 10,
        addressLandlord, "lock data", 1, 1, guidTestLandlord, 100, {from:accounts[1]});
        var jsonContractInfo = await contractFactoty.GetContractInfo(guidTestLandlord);
        //["1539200057","1","0",false,"335",false,"lock data","235","0","1"]
        console.log("Before", JSON.stringify(jsonContractInfo));
        assert.equal(1, jsonContractInfo[1]);
        assert.equal(0, jsonContractInfo[2]);

        await contractFactoty.LandlordTerminate(10, guidTestLandlord, {from:accounts[2]});

        jsonContractInfo = await contractFactoty.GetContractInfo(guidTestLandlord);
        console.log("After", JSON.stringify(jsonContractInfo));
        assert.equal(3, jsonContractInfo[1]);
    });

});

