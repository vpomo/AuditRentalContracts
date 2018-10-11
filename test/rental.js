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

contract('MyToken and StayBitContractFactory', (accounts) => {
    var addressLandlord = accounts[2];
    var guid = "23fff-fhgjg";

    var guidTestTenant = "23fff-tenantTerminate";
    var guidTestLandlord = "23fff-landlordTerminate";
    var guidTestMoveIn = "23fff-tenantMoveIn";


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

        await contractToken.faucetWithdrawToken(1e3, {from:accounts[1]});
        var balanceAccountOne = await contractToken.balanceOf.call(accounts[1]);
        assert.equal(1e3, Number(balanceAccountOne));
        await contractToken.approve(contractFactoty.address, 1e21, {from:accounts[1]});

        await contractToken.faucetWithdrawToken(1e3, {from:accounts[4]});
        await contractToken.approve(contractFactoty.address, 1e21, {from:accounts[4]});

    });

    it('set address MyTokenContract to contractFactoty', async ()  => {
        //function SetTokenInfo(uint tokenId, address tokenAddress, uint rentMin, uint rentMax)
        await contractFactoty.SetTokenInfo(1, contractToken.address, 30, 70);
    });

    it('set factory params and create contractFactory', async ()  => {
        await contractFactoty.SetFactoryParams(true, true, 10);
		//Mon, 15 Oct 2018
		//Sat, 20 Oct 2018
        await contractFactoty.CreateContract(45, 1, 1539561600, 1539993600, 10,
        addressLandlord, "lock data", 1, 1, guid, 100, {from:accounts[1]});
    });

    it('test terminate contract by Tenant', async ()  => {

		//Mon, 15 Oct 2018
		//Sat, 20 Oct 2018
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

        var jsonContractInfo = await contractFactoty.GetContractInfo(guidTestTenant);
        assert.equal(1, jsonContractInfo[1]);
        assert.equal(0, jsonContractInfo[2]);

         var balanceTenant = await contractToken.balanceOf.call(accounts[1]);
         var balanceLandlord = await contractToken.balanceOf.call(accounts[2]);

        assert.equal(284, balanceTenant);
        assert.equal(0, balanceLandlord);

        await contractFactoty.TenantTerminate(guidTestTenant, {from:accounts[1]});
        jsonContractInfo = await contractFactoty.GetContractInfo(guidTestTenant);
        assert.equal(2, jsonContractInfo[1]);

          balanceTenant = await contractToken.balanceOf.call(accounts[1]);
          balanceLandlord = await contractToken.balanceOf.call(accounts[2]);

        assert.equal(574, balanceTenant);
        assert.equal(45, balanceLandlord);
    });

    it('test terminate contract by Landlord', async ()  => {
		//Mon, 15 Oct 2018
		//Sat, 20 Oct 2018
        await contractFactoty.CreateContract(45, 1, 1539561600, 1539993600, 10,
        addressLandlord, "lock data", 1, 1, guidTestLandlord, 100, {from:accounts[1]});
        var jsonContractInfo = await contractFactoty.GetContractInfo(guidTestLandlord);

        assert.equal(1, jsonContractInfo[1]);
        assert.equal(0, jsonContractInfo[2]);

        var balanceTenant = await contractToken.balanceOf.call(accounts[1]);
        var balanceLandlord = await contractToken.balanceOf.call(accounts[2]);

        assert.equal(216, balanceTenant);
        assert.equal(45, balanceLandlord);

        await contractFactoty.LandlordTerminate(10, guidTestLandlord, {from:accounts[2]});

        jsonContractInfo = await contractFactoty.GetContractInfo(guidTestLandlord);
        assert.equal(3, jsonContractInfo[1]);

        balanceTenant = await contractToken.balanceOf.call(accounts[1]);
        balanceLandlord = await contractToken.balanceOf.call(accounts[2]);

        assert.equal(551, balanceTenant);
        assert.equal(45, balanceLandlord);

    });

    it('test Tenant MoveIn', async ()  => {
		var balanceTenant = await contractToken.balanceOf.call(accounts[4]);
        var balanceLandlord = await contractToken.balanceOf.call(accounts[2]);

        assert.equal(1000, balanceTenant);
        assert.equal(45, balanceLandlord);
	
		//Mon, 15 Oct 2018
		//Sat, 20 Oct 2018
        await contractFactoty.CreateContract(45, 1, 1539561600, 1539993600, 10,
            addressLandlord, "lock data", 1, 1, guidTestMoveIn, 100, {from:accounts[4]});

    	//Thu, 11 Oct 2018
        await contractFactoty.SimulateCurrentDate(1539216000, guidTestMoveIn, {from:accounts[4]});

			var jsonContractInfo = await contractFactoty.GetContractInfo(guidTestMoveIn);
        assert.equal(1, jsonContractInfo[1]);
        assert.equal(0, jsonContractInfo[2]);

        balanceTenant = await contractToken.balanceOf.call(accounts[4]);
        balanceLandlord = await contractToken.balanceOf.call(accounts[2]);

        assert.equal(642, balanceTenant);
        assert.equal(45, balanceLandlord);

		//Mon, 15 Oct 2018
        await contractFactoty.SimulateCurrentDate(1539562600, guidTestMoveIn, {from:accounts[4]});

        await contractFactoty.TenantMoveIn(guidTestMoveIn, {from:accounts[4]});
		
		//Tue, 20 Nov 2018 
        await contractFactoty.SimulateCurrentDate(1542672000, guidTestMoveIn, {from:accounts[4]});

        await contractFactoty.TenantTerminate(guidTestMoveIn, {from:accounts[4]});

        jsonContractInfo = await contractFactoty.GetContractInfo(guidTestMoveIn);
        assert.equal(8, jsonContractInfo[1]);

        balanceTenant = await contractToken.balanceOf.call(accounts[4]);
        balanceLandlord = await contractToken.balanceOf.call(accounts[2]);

        assert.equal(752, balanceTenant);
        assert.equal(270, balanceLandlord);

    });

});

