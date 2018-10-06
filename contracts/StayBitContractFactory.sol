pragma solidity ^0.4.15;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract ERC20Interface {
	function totalSupply() public constant returns (uint);
	function balanceOf(address tokenOwner) public constant returns (uint balance);
	function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract  IFlexibleEscrowLib {
	function TenantTerminate(IBaseEscrowLib.EscrowContractState self) public;
	function TenantMoveIn(IBaseEscrowLib.EscrowContractState self) public;
	function TenantTerminateMisrep(IBaseEscrowLib.EscrowContractState self) public;
	function LandlordTerminate(IBaseEscrowLib.EscrowContractState self, uint SecDeposit) public;
}

contract IModerateEscrowLib {
	function TenantTerminate(IBaseEscrowLib.EscrowContractState self) public;
	function TenantMoveIn(IBaseEscrowLib.EscrowContractState self) public;
	function TenantTerminateMisrep(IBaseEscrowLib.EscrowContractState self) public;
	function LandlordTerminate(IBaseEscrowLib.EscrowContractState self, uint SecDeposit) public;
}

contract IStrictEscrowLib {
	function TenantTerminate(IBaseEscrowLib.EscrowContractState self) public;
	function TenantMoveIn(IBaseEscrowLib.EscrowContractState self) public;
	function TenantTerminateMisrep(IBaseEscrowLib.EscrowContractState self) public;
	function LandlordTerminate(IBaseEscrowLib.EscrowContractState self, uint SecDeposit) public;
}

contract  IBaseEscrowLib {
	struct EscrowContractState {
		uint _CurrentDate;
		uint _CreatedDate;
		int _RentPerDay;
		uint _MoveInDate;
		uint _MoveOutDate;
		int _TotalAmount;
		int _SecDeposit;
		int _State;
		uint _ActualMoveInDate;
		uint _ActualMoveOutDate;
		address _landlord;
		address _tenant;
		bool _TenantConfirmedMoveIn;
		bool _MisrepSignaled;
		string _DoorLockData;
		address _ContractAddress;
		ERC20Interface _tokenApi;
		int _landlBal;
		int _tenantBal;
		int _Id;
		int _CancelPolicy;
		uint _Balance;
		string _Guid;
	}
	function ContractLogEvent(int stage, int atype, uint timestamp, string guid, string text) public;
	function GetContractStateActive() public constant returns (int);
	function GetContractStateCancelledByTenant() public constant returns (int);
	function GetContractStateCancelledByLandlord() public constant returns (int);
	function GetContractStateTerminatedMisrep() public constant returns (int);
	function GetContractStateEarlyTerminatedByTenant() public constant returns (int);
	function GetContractStateEarlyTerminatedByTenantSecDep() public constant returns (int);
	function GetContractStateEarlyTerminatedByLandlord() public constant returns (int);
	function GetContractStateTerminatedOK() public constant returns (int);
	function GetContractStateTerminatedSecDep() public constant returns (int);
	function GetContractStagePreMoveIn() public constant returns (int);
	function GetContractStageLiving() public constant returns (int);
	function GetContractStageTermination() public constant returns (int);
	function GetLogMessageInfo() public constant returns (int);
	function GetLogMessageWarning() public constant returns (int);
	function GetLogMessageError() public constant returns (int);
	function initialize(EscrowContractState self) public;
	function TerminateContract(EscrowContractState self, int tenantBal, int landlBal, int state) public;
	function GetCurrentStage(EscrowContractState self) public constant returns (int stage);
	function SimulateCurrentDate(EscrowContractState self, uint n) public;
	function GetCurrentDate(EscrowContractState self) public constant returns (uint nCurrentDate);
	function GetContractBalance(EscrowContractState self) public returns (uint res);
	function splitBalanceAccordingToRatings(int balance, int tenantScore, int landlScore) public constant returns (int tenantBal, int landlBal);
	function formatDate(uint dt) public constant returns (string strDate);

}

contract StayBitContractFactory is Ownable
{
    struct EscrowTokenInfo { 
		uint _RentMin;  //Min value for rent per day
		uint _RentMax;  //Max value for rent per day
		address _ContractAddress; //Token address
		uint _ContractFeeBal;  //Earned balance
    }

	IFlexibleEscrowLib private FlexibleEscrowLib;
	IModerateEscrowLib private ModerateEscrowLib;
	IStrictEscrowLib private StrictEscrowLib;
	IBaseEscrowLib private BaseEscrowLib;

	//using BaseEscrowLib for IBaseEscrowLib.EscrowContractState;
    mapping(bytes32 => IBaseEscrowLib.EscrowContractState) private contracts;
	mapping(uint => EscrowTokenInfo) private supportedTokens;
	bool private CreateEnabled; // Enables / disables creation of new contracts
	bool private PercentageFee;  // true - percentage fee per contract false - fixed fee per contract
	uint ContractFee;  //Either fixed amount or percentage

	event contractCreated(int rentPerDay, int cancelPolicy, uint moveInDate, uint moveOutDate, int secDeposit, address landlord, uint tokenId, int Id, string Guid, uint extraAmount);
	event contractTerminated(int Id, string Guid, int State);

	function StayBitContractFactory()
	{
		CreateEnabled = true;
		PercentageFee = false;
		ContractFee = 0;
	}

	function SetFactoryParams(bool enable, bool percFee, uint contrFee) public onlyOwner
	{
		CreateEnabled = enable;	
		PercentageFee = percFee;
		ContractFee = contrFee;
	}

	function SetLibrary(address addressFlexible, address addressModerate, address addressStrict, address addressBaseEscrowLib) public onlyOwner
	{
		FlexibleEscrowLib = IFlexibleEscrowLib(addressFlexible);
		ModerateEscrowLib = IModerateEscrowLib(addressModerate);
		StrictEscrowLib = IStrictEscrowLib(addressStrict);
		BaseEscrowLib = IBaseEscrowLib(addressBaseEscrowLib);
	}

	function GetFeeBalance(uint tokenId) public constant returns (uint)
	{
		return supportedTokens[tokenId]._ContractFeeBal;
	}

	function WithdrawFeeBalance(uint tokenId, address to, uint amount) public onlyOwner
	{	    
		require(supportedTokens[tokenId]._RentMax > 0);		
		require(supportedTokens[tokenId]._ContractFeeBal >= amount);		
		supportedTokens[tokenId]._ContractFeeBal -= amount;		
		ERC20Interface tokenApi = ERC20Interface(supportedTokens[tokenId]._ContractAddress);
		tokenApi.transfer(to, amount);
	}


	function SetTokenInfo(uint tokenId, address tokenAddress, uint rentMin, uint rentMax) public onlyOwner
	{
		supportedTokens[tokenId]._RentMin = rentMin;
		supportedTokens[tokenId]._RentMax = rentMax;
		supportedTokens[tokenId]._ContractAddress = tokenAddress;
	}

	function CalculateCreateFee(uint amount) public constant returns (uint)
	{
		uint result = 0;
		if (PercentageFee)
		{
			result = amount * ContractFee / 100;
		}
		else
		{
			result = ContractFee;
		}
		return result;
	}


    //75, 1, 1533417601, 1534281601, 100, "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", "", "0x4514d8d91a10bda73c10e2b8ffd99cb9646620a9", 1, "test"
	function CreateContract(int rentPerDay, int cancelPolicy, uint moveInDate, uint moveOutDate, int secDeposit, address landlord, string doorLockData, uint tokenId, int Id, string Guid, uint extraAmount) public
	{
		//It must be enabled
		require (CreateEnabled && rentPerDay > 0 && secDeposit > 0 && moveInDate > 0 && moveOutDate > 0 && landlord != address(0) && landlord != msg.sender && Id > 0);

		//Token must be supported
		require(supportedTokens[tokenId]._RentMax > 0);

		//Rent per day values must be within range for this token
		require(supportedTokens[tokenId]._RentMin <= uint(rentPerDay) && supportedTokens[tokenId]._RentMax >= uint(rentPerDay));

		//Check that we support cancel policy
		//TESTNET
		//require (cancelPolicy == 1 || cancelPolicy == 2 || cancelPolicy == 3);

		//PRODUCTION
		require (cancelPolicy == 1 || cancelPolicy == 2);

		//Check that GUID does not exist		
		require (contracts[keccak256(abi.encodePacked(Guid))]._Id == 0);

		contracts[keccak256(abi.encodePacked(Guid))]._CurrentDate = now;
		contracts[keccak256(abi.encodePacked(Guid))]._CreatedDate = now;
		contracts[keccak256(abi.encodePacked(Guid))]._RentPerDay = rentPerDay;
		contracts[keccak256(abi.encodePacked(Guid))]._MoveInDate = moveInDate;
		contracts[keccak256(abi.encodePacked(Guid))]._MoveOutDate = moveOutDate;
		contracts[keccak256(abi.encodePacked(Guid))]._SecDeposit = secDeposit;
		contracts[keccak256(abi.encodePacked(Guid))]._DoorLockData = doorLockData;
		contracts[keccak256(abi.encodePacked(Guid))]._landlord = landlord;
		contracts[keccak256(abi.encodePacked(Guid))]._tenant = msg.sender;
		contracts[keccak256(abi.encodePacked(Guid))]._ContractAddress = this;		
		contracts[keccak256(abi.encodePacked(Guid))]._tokenApi = ERC20Interface(supportedTokens[tokenId]._ContractAddress);
		contracts[keccak256(abi.encodePacked(Guid))]._Id = Id;
		contracts[keccak256(abi.encodePacked(Guid))]._Guid = Guid;
		contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy = cancelPolicy;

		BaseEscrowLib.initialize(contracts[keccak256(abi.encodePacked(Guid))]);

		uint256 startBalance = contracts[keccak256(abi.encodePacked(Guid))]._tokenApi.balanceOf(this);

		//Calculate our fees
		supportedTokens[tokenId]._ContractFeeBal += CalculateCreateFee(uint(contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount));

		//Check that tenant has funds
		require(extraAmount + uint(contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount) + CalculateCreateFee(uint(contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount)) <= contracts[keccak256(abi.encodePacked(Guid))]._tokenApi.balanceOf(msg.sender));

		//Fund. Token fee, if any, will be witheld here 
		contracts[keccak256(abi.encodePacked(Guid))]._tokenApi.transferFrom(msg.sender, this, extraAmount + uint(contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount) + CalculateCreateFee(uint(contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount)));

		//We need to measure balance diff because some tokens (TrueUSD) charge fees per transfer
		contracts[keccak256(abi.encodePacked(Guid))]._Balance = contracts[keccak256(abi.encodePacked(Guid))]._tokenApi.balanceOf(this) - startBalance - CalculateCreateFee(uint(contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount));

		//Check that balance is still greater than contract's amount
		require(contracts[keccak256(abi.encodePacked(Guid))]._Balance >= uint(contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount));

		//raise event
		emit contractCreated(rentPerDay, cancelPolicy, moveInDate, moveOutDate, secDeposit, landlord, tokenId, Id, Guid, extraAmount);
	}

	function() payable
	{	
		revert();
	}

	function SimulateCurrentDate(uint n, string Guid) public {
	    if (contracts[keccak256(abi.encodePacked(Guid))]._Id != 0)
		{
			//contracts[keccak256(abi.encodePacked(Guid))].SimulateCurrentDate(n);
			BaseEscrowLib.SimulateCurrentDate(contracts[keccak256(abi.encodePacked(Guid))], n);
		}
	}
	
	
	function GetContractInfo(string Guid) public constant returns (uint curDate, int escrState, int escrStage, bool tenantMovedIn, uint actualBalance, bool misrepSignaled, string doorLockData, int calcAmount, uint actualMoveOutDate, int cancelPolicy)
	{
		if (contracts[keccak256(abi.encodePacked(Guid))]._Id != 0)
		{
			//actualBalance = contracts[keccak256(abi.encodePacked(Guid))].GetContractBalance();
			actualBalance = BaseEscrowLib.GetContractBalance(contracts[keccak256(abi.encodePacked(Guid))]);
			//curDate = contracts[keccak256(abi.encodePacked(Guid))].GetCurrentDate();
			//curDate = BaseEscrowLib.GetCurrentDate(contracts[keccak256(abi.encodePacked(Guid))]);
			tenantMovedIn = contracts[keccak256(abi.encodePacked(Guid))]._TenantConfirmedMoveIn;
			misrepSignaled = contracts[keccak256(abi.encodePacked(Guid))]._MisrepSignaled;
/*
			doorLockData = contracts[keccak256(abi.encodePacked(Guid))]._DoorLockData;
*/
			//escrStage = contracts[keccak256(abi.encodePacked(Guid))].GetCurrentStage();

			escrStage = BaseEscrowLib.GetCurrentStage(contracts[keccak256(abi.encodePacked(Guid))]);
			escrState = contracts[keccak256(abi.encodePacked(Guid))]._State;
//			calcAmount = contracts[keccak256(abi.encodePacked(Guid))]._TotalAmount;
//			actualMoveOutDate = contracts[keccak256(abi.encodePacked(Guid))]._ActualMoveOutDate;
//			cancelPolicy = contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy;

		}
	}

/*
	function TenantTerminate(string Guid) public
	{
		if (contracts[keccak256(abi.encodePacked(Guid))]._Id != 0)
		{
			require(contracts[keccak256(abi.encodePacked(Guid))]._State == BaseEscrowLib.GetContractStateActive() && msg.sender == contracts[keccak256(abi.encodePacked(Guid))]._tenant);

			if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 1)
			{
				FlexibleEscrowLib.TenantTerminate(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 2)
			{
				ModerateEscrowLib.TenantTerminate(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 3)
			{
				StrictEscrowLib.TenantTerminate(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else{
				revert();
				return;
			}

			SendTokens(Guid);

			//Raise event
			emit contractTerminated(contracts[keccak256(abi.encodePacked(Guid))]._Id, Guid, contracts[keccak256(abi.encodePacked(Guid))]._State);

		}
	}

	function TenantTerminateMisrep(string Guid) public
	{	
		if (contracts[keccak256(abi.encodePacked(Guid))]._Id != 0)
		{
			require(contracts[keccak256(abi.encodePacked(Guid))]._State == BaseEscrowLib.GetContractStateActive() && msg.sender == contracts[keccak256(abi.encodePacked(Guid))]._tenant);

			if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 1)
			{
				FlexibleEscrowLib.TenantTerminateMisrep(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 2)
			{
				ModerateEscrowLib.TenantTerminateMisrep(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 3)
			{
				StrictEscrowLib.TenantTerminateMisrep(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else{
				revert();
				return;
			}

			SendTokens(Guid);

			//Raise event
			emit contractTerminated(contracts[keccak256(abi.encodePacked(Guid))]._Id, Guid, contracts[keccak256(abi.encodePacked(Guid))]._State);
		}
	}
*/

/*
	function TenantMoveIn(string Guid) public
	{	
		if (contracts[keccak256(abi.encodePacked(Guid))]._Id != 0)
		{
			require(contracts[keccak256(abi.encodePacked(Guid))]._State == BaseEscrowLib.GetContractStateActive() && msg.sender == contracts[keccak256(abi.encodePacked(Guid))]._tenant);

			if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 1)
			{
				FlexibleEscrowLib.TenantMoveIn(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 2)
			{
				ModerateEscrowLib.TenantMoveIn(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 3)
			{
				StrictEscrowLib.TenantMoveIn(contracts[keccak256(abi.encodePacked(Guid))]);
			}
			else{
				revert();
			}
		}
	}
*/

/*
	function LandlordTerminate(uint SecDeposit, string Guid) public
	{		
		if (contracts[keccak256(abi.encodePacked(Guid))]._Id != 0)
		{
			require(SecDeposit >= 0 && SecDeposit <= uint256(contracts[keccak256(abi.encodePacked(Guid))]._SecDeposit));
			require(contracts[keccak256(abi.encodePacked(Guid))]._State == BaseEscrowLib.GetContractStateActive() && msg.sender == contracts[keccak256(abi.encodePacked(Guid))]._landlord);

			if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 1)
			{
				FlexibleEscrowLib.LandlordTerminate(contracts[keccak256(abi.encodePacked(Guid))], SecDeposit);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 2)
			{
				ModerateEscrowLib.LandlordTerminate(contracts[keccak256(abi.encodePacked(Guid))], SecDeposit);
			}
			else if (contracts[keccak256(abi.encodePacked(Guid))]._CancelPolicy == 3)
			{
				StrictEscrowLib.LandlordTerminate(contracts[keccak256(abi.encodePacked(Guid))], SecDeposit);
			}
			else{
				revert();
				return;
			}

			SendTokens(Guid);

			//Raise event
			emit contractTerminated(contracts[keccak256(abi.encodePacked(Guid))]._Id, Guid, contracts[keccak256(abi.encodePacked(Guid))]._State);
		}
	}
*/

	function SendTokens(string Guid) private
	{		
		if (contracts[keccak256(abi.encodePacked(Guid))]._Id != 0)
		{
			if (contracts[keccak256(abi.encodePacked(Guid))]._landlBal > 0)
			{	
				uint landlBal = uint(contracts[keccak256(abi.encodePacked(Guid))]._landlBal);
				contracts[keccak256(abi.encodePacked(Guid))]._landlBal = 0;
				contracts[keccak256(abi.encodePacked(Guid))]._tokenApi.transfer(contracts[keccak256(abi.encodePacked(Guid))]._landlord, landlBal);
				contracts[keccak256(abi.encodePacked(Guid))]._Balance -= landlBal;
			}
	    
			if (contracts[keccak256(abi.encodePacked(Guid))]._tenantBal > 0)
			{			
				uint tenantBal = uint(contracts[keccak256(abi.encodePacked(Guid))]._tenantBal);
				contracts[keccak256(abi.encodePacked(Guid))]._tenantBal = 0;
				contracts[keccak256(abi.encodePacked(Guid))]._tokenApi.transfer(contracts[keccak256(abi.encodePacked(Guid))]._tenant, tenantBal);
				contracts[keccak256(abi.encodePacked(Guid))]._Balance -= tenantBal;
			}
		}			    
	}

}