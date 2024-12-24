// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {DexLocker} from "./DexLocker.sol";
import "../Errors.sol";


/// @title DexLockerFactory
/// @notice Factory contract for creating DexLocker instances using Clones - Used to avoid contract size becoming too large
contract DexLockerFactory {
    /// @notice Address of the DexLocker implementation contract
    address   _dexLockerImplementationAddress;
    address  _coinVaultImplementationAddress;

    

    constructor(address  dexLockerImplementationAddress,address  coinVaultImplementationAddress){
        _dexLockerImplementationAddress=dexLockerImplementationAddress;
        _coinVaultImplementationAddress=coinVaultImplementationAddress;
    }
    

    /// @notice Creates a new DexLocker instance
    /// @param dexRouterAddress Address of the DEX router
    /// @param salesTokenAddress Address of the sales token
    /// @param purchaseTokenAddress Address of the purchase token
    /// @param deployer Address of the deployer
    /// @param owner Address of the locker owner
    /// @return Address of the newly created DexLocker instance
    function createDexLocker(address dexRouterAddress, address salesTokenAddress, address purchaseTokenAddress,address deployer,address owner)  public returns(address) {
        require(dexRouterAddress != address(0), InvalidDexRouterAddress(dexRouterAddress));
        require(salesTokenAddress != address(0), InvalidSalesTokenAddress(salesTokenAddress));
        // require(purchaseTokenAddress != address(0), InvalidPurchaseTokenAddress(purchaseTokenAddress));
        require(deployer != address(0), InvalidDeployerAddress(deployer));
        require(owner != address(0), InvalidOwnerAddress(owner));

        address payable newCloneAddress = payable(Clones.clone(_dexLockerImplementationAddress ) );
        DexLocker(newCloneAddress).initialize(salesTokenAddress,purchaseTokenAddress, deployer, owner,_coinVaultImplementationAddress);

        return  newCloneAddress;
    }
}