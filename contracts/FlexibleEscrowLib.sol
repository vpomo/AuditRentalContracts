pragma solidity ^0.4.15;

import "./DateTime.sol";
import "./BaseEscrowLib.sol";



library FlexibleEscrowLib
{
	using BaseEscrowLib for BaseEscrowLib.EscrowContractState;

    //Cancel days
	int internal constant FreeCancelBeforeMoveInDays = 14;

	//Expiration
	int internal constant ExpireAfterMoveOutDays = 14;
		    

    
	function TenantTerminate(BaseEscrowLib.EscrowContractState storage self) public
    {
		int nCurrentStage = BaseEscrowLib.GetCurrentStage(self);
		uint nCurrentDate = BaseEscrowLib.GetCurrentDate(self);
		int nActualBalance = int(BaseEscrowLib.GetContractBalance(self));
		int tenantBal = 0;
		int landlBal = 0;
		int state = 0; 
		bool bProcessed = false;
        string memory sGuid;
        sGuid = self._Guid;

		if (nActualBalance == 0)
		{
			//If contract is unfunded, just cancel it
			state = BaseEscrowLib.GetContractStateCancelledByTenant();
			bProcessed = true;			
		}
		else if (nCurrentStage == BaseEscrowLib.GetContractStagePreMoveIn())
		{			
			int nDaysBeforeMoveIn = (int)(self._MoveInDate - nCurrentDate) / (60 * 60 * 24);
			if (nDaysBeforeMoveIn < FreeCancelBeforeMoveInDays)
			{
				//Pay cancel fee
				//Contract must be fully funded
				require(self._RentPerDay <= nActualBalance);

				//Cancellation fee is one day rent
				tenantBal = nActualBalance - self._RentPerDay;
				landlBal = self._RentPerDay;
				state = BaseEscrowLib.GetContractStateCancelledByTenant();
				bProcessed = true;

				BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageWarning(), nCurrentDate, sGuid, "Tenant cancelled escrow. Cancellation fee will be withheld from tenant.");										
			}
			else
			{
				//No cancel fee
				tenantBal = nActualBalance;
				landlBal = 0;
				state = BaseEscrowLib.GetContractStateCancelledByTenant();
				bProcessed = true;

				BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageWarning(), nCurrentDate, sGuid, "Tenant cancelled escrow.");
			}					
		}
		else if (nCurrentStage == BaseEscrowLib.GetContractStageLiving())
		{
			state = 0;
			self._ActualMoveOutDate = nCurrentDate;
			bProcessed = true;
			//In this case landlord will close escrow

			BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageWarning(), nCurrentDate, sGuid, "Tenant signaled early move-out");
		}
		else if (nCurrentStage == BaseEscrowLib.GetContractStageTermination())
		{
			//If landlord did not close the escrow, and if it is expired, tenant may only pay for rent without sec deposit
			int nDaysAfterMoveOut = (int)(nCurrentDate - self._MoveOutDate) / (60 * 60 * 24);

			if (nDaysAfterMoveOut > ExpireAfterMoveOutDays)
			{
				int nPotentialBillableDays = (int)(self._MoveOutDate - self._MoveInDate) / (60 * 60 * 24);
				require(self._RentPerDay * nPotentialBillableDays <= nActualBalance);

				landlBal = self._RentPerDay * nPotentialBillableDays;
				tenantBal = nActualBalance - landlBal;
				bProcessed = true;
				state = BaseEscrowLib.GetContractStateTerminatedOK();

				BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageInfo(), nCurrentDate, sGuid, "Tenant closed escrow because it was expired");
			}
		}

		require(bProcessed);
		if (state > 0)
		{
			BaseEscrowLib.TerminateContract(self,tenantBal,landlBal,state);
		}

    }
    
    function TenantMoveIn(BaseEscrowLib.EscrowContractState storage self) public
    {
		int nCurrentStage = BaseEscrowLib.GetCurrentStage(self);
		uint nCurrentDate = BaseEscrowLib.GetCurrentDate(self);
		int nActualBalance = int(BaseEscrowLib.GetContractBalance(self));
		string memory sGuid;
        sGuid = self._Guid;
				
		require(nCurrentStage == BaseEscrowLib.GetContractStagePreMoveIn() && nActualBalance >= self._TotalAmount && 
				DateTime.compareDateTimesForContract(nCurrentDate, self._MoveInDate) >= 0);

        BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageInfo(), nCurrentDate, sGuid, "Tenant signaled move-in");

		self._TenantConfirmedMoveIn = true;
    } 
	       
    function TenantTerminateMisrep(BaseEscrowLib.EscrowContractState storage self) public
    {
		int nCurrentStage = BaseEscrowLib.GetCurrentStage(self);
		uint nCurrentDate = BaseEscrowLib.GetCurrentDate(self);
		int nActualBalance = int(BaseEscrowLib.GetContractBalance(self));
		int tenantBal = 0;
		int landlBal = 0;
        string memory sGuid;
        sGuid = self._Guid;

		require(nCurrentStage == BaseEscrowLib.GetContractStagePreMoveIn() && nActualBalance >= self._RentPerDay && 
				DateTime.compareDateTimesForContract(nCurrentDate, self._MoveInDate) == 0);

		(tenantBal, landlBal) = BaseEscrowLib.splitBalanceAccordingToRatings(self._RentPerDay,0,0);
					
		tenantBal = nActualBalance - landlBal;
		
		BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageWarning(), nCurrentDate, sGuid, "Tenant signaled misrepresentation and terminated escrow!");
		self._MisrepSignaled = true;

		BaseEscrowLib.TerminateContract(self,tenantBal,landlBal,BaseEscrowLib.GetContractStateTerminatedMisrep());	         
    }    
	
	function LandlordTerminate(BaseEscrowLib.EscrowContractState storage self, uint SecDeposit) public
	{
		int nCurrentStage = BaseEscrowLib.GetCurrentStage(self);
		uint nCurrentDate = BaseEscrowLib.GetCurrentDate(self);
		int nActualBalance = int(BaseEscrowLib.GetContractBalance(self));
		int tenantBal = 0;
		int landlBal = 0;
		int state = 0; 
		bool bProcessed = false;
		int nPotentialBillableDays = 0;
        string memory sGuid;
        sGuid = self._Guid;

		if (nActualBalance == 0)
		{
			//If contract is unfunded, just cancel it
			state = BaseEscrowLib.GetContractStateCancelledByLandlord();
			bProcessed = true;			
		}
		else if (nCurrentStage == BaseEscrowLib.GetContractStagePreMoveIn())
		{	
			if (DateTime.compareDateTimesForContract(nCurrentDate, self._MoveInDate) > 0 && 
				!self._TenantConfirmedMoveIn)
			{
				//Landlord gets cancell fee if tenant did not signal anything after move in date
				tenantBal = nActualBalance - self._RentPerDay;	
				landlBal = self._RentPerDay;
				state = BaseEscrowLib.GetContractStateCancelledByLandlord();
				bProcessed = true;
				BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageWarning(), nCurrentDate, sGuid, "Landlord cancelled escrow. Tenant did not show up and will pay cancellation fee.");								
			}
			else
			{		        				
				//No cancel fee
				tenantBal = nActualBalance;
				landlBal = 0;
				state = BaseEscrowLib.GetContractStateCancelledByLandlord();
				bProcessed = true;
				BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageInfo(), nCurrentDate, sGuid, "Landlord cancelled esqrow");								
			}
		}
		else if (nCurrentStage == BaseEscrowLib.GetContractStageLiving())
		{
			nPotentialBillableDays = (int)(nCurrentDate - self._MoveInDate) / (60 * 60 * 24);
			
			if (self._ActualMoveOutDate == 0)
			{
				//If landlord initiates it, he cannot claim sec deposit
				require(nActualBalance >= nPotentialBillableDays * self._RentPerDay);
				state = BaseEscrowLib.GetContractStateEarlyTerminatedByLandlord();
				landlBal = nPotentialBillableDays * self._RentPerDay;
				tenantBal = nActualBalance - landlBal;
				bProcessed = true;
				BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageInfo(), nCurrentDate, sGuid, "Landlord signaled early move-out");
			}
			else{
				//If tenant initiates it, landlord can claim sec deposit, and tenant pays for one extra day
				require(int(SecDeposit) <= self._SecDeposit && nActualBalance >= (nPotentialBillableDays + 1) * self._RentPerDay + int(SecDeposit));
				
				if (SecDeposit == 0)
				{
					state = BaseEscrowLib.GetContractStateEarlyTerminatedByTenant();
				}
				else
				{
					BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageInfo(), nCurrentDate, sGuid, "Landlord signaled Security Deposit");
					state = BaseEscrowLib.GetContractStateEarlyTerminatedByTenantSecDep();
				}

				landlBal = (nPotentialBillableDays + 1) * self._RentPerDay + int(SecDeposit);
				tenantBal = nActualBalance - landlBal;
				bProcessed = true;
			}
		}
		else if (nCurrentStage == BaseEscrowLib.GetContractStageTermination())
		{
			nPotentialBillableDays = (int)(self._MoveOutDate - self._MoveInDate) / (60 * 60 * 24);
			require(int(SecDeposit) <= self._SecDeposit && nActualBalance >= nPotentialBillableDays * self._RentPerDay + int(SecDeposit));
			if (SecDeposit == 0)
			{
				state = BaseEscrowLib.GetContractStateTerminatedOK();
			}
			else
			{
				BaseEscrowLib.ContractLogEvent(nCurrentStage, BaseEscrowLib.GetLogMessageInfo(), nCurrentDate, sGuid, "Landlord signaled Security Deposit");
				state = BaseEscrowLib.GetContractStateTerminatedSecDep();
			}
			landlBal = nPotentialBillableDays * self._RentPerDay + int(SecDeposit);
			tenantBal = nActualBalance - landlBal;
			bProcessed = true;
		}

		require(bProcessed);
		if (state > 0)
		{
			BaseEscrowLib.TerminateContract(self,tenantBal,landlBal,state);
		}	
	}
}

