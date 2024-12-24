// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

error OnlyDeployer();
error NoToken();
error NoZeroTokenAddress();
error NoEthForLiquidity();
error NoTokenBalanceForLiquidity();
error NoPurchaseTokensForLiquidity();
error NoTokensForLiquidity();
error RouterApprovalFailed();

error AlreadyReachedSoftCap(uint cap);

error LiquiditySetupAlreadyDone();

error AddLiquidityNotCalledYet();
error NoLPTokensToRelease();
error NoTokensToRelease();
error NoPurchaseTokensToRelease();
error CurrentTimeIsBeforeRelease();

error SaleEndTimeBeforeStartTime();
error LiquidityAboveLimit(uint limit);

error UpdateAfterSaleStartTime();

error TierCapTooLow(uint limit);
error TierCapsExceedHardCap();
error TierOneCapExceedsHardCap();
error TierTwoCapExceedsHardCap();
error MinAllocationOutOfRange();
error TierOneMaxAllocationOutOfRange();
error TierTwoMaxAllocationOutOfRange();
error HardCapGreaterThanX4OfSoftCap();

error NotOwner();
error NotAdmin();
error CannotCancelAfterSaleStartTime();
error PostponeBeforeSaleStartTime();
error NewDateLessThanOldDate();
error EndDateLessThanStartTime();

error AlterWhitelistingAfterSaleStartTime();

error KYCAfterSaleStartTime();
error AuditAfterSaleStartTime();

error SaleCancelled();
error SaleFailed();
error NotTokenSubmitted();
error SoldOutError();
error ClosedSale();
error ExceedMaxCap();
error LessThanMinBuy();


error NotInTier2Whitelist();
error ExceedTierTwoMaxCap();
error ExceedTierTwoUserLimit();
error NotInTier0();
error ExceedTierZeroMaxCap();
error ExceedTierZeroUserLimit();
error NotInTier1();
error ExceedTierOneMaxCap();
error ExceedTierOneUserLimit();
error SaleNotStarted();

error OwnersCannotWithdraw();
error OngoingSales();
error NoCoinsToClaim();
error NoCoin();

error CampaignFailedOrCancelled();
error CampaignCancelled();

error NotEndDate();
error NoReachSoftCap();

error RequireCancelorFail();
error NoTokens();

error NoSoldOutOrEndDate();

error OnlyDecimals18AndBelow();

error TransferDExLockerFailed();

error OwnerHasWithdrawnAlready();


error InvalidDexRouterAddress(address addr);
error InvalidSalesTokenAddress(address addr);
error InvalidPurchaseTokenAddress(address addr);
error InvalidOwnerAddress(address addr);
error InvalidDeployerAddress(address addr);