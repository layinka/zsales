// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";


contract Test {
    bytes public t;
    uint hardCap= 100 ether;

    uint public usdcDecimals = 6;
    uint public pbtDecimals = 18;//base
    // uint public exchangeRateWei;

    constructor()  {
        
    }

    

    function calculatePBT(uint exchangeRateWei, uint amountUSDCWei) public view returns (uint) {
        return amountUSDCWei * exchangeRateWei;
    }

    function calculatePBT2(uint exchangeRateWei, uint amountUSDCWei) public view returns (uint) {
        return (amountUSDCWei * exchangeRateWei) / (10**(pbtDecimals - usdcDecimals   ));
    }

    function calculatePBTDiv(uint exchangeRate, uint amountUSDCWei) public view returns (uint) {
        return (amountUSDCWei * exchangeRate) / (10**(pbtDecimals - usdcDecimals   ));  //base - token
    }

    function calculatePBT3(uint exchangeRateWei, uint amountUSDCWei) public view returns (uint) {
        //10 ** 18 / value * presale_info.selling_amount
        return 10 ** 18 / (amountUSDCWei * exchangeRateWei) ; // / (10**(usdcDecimals - pbtDecimals  ));
    }



    function bytesToAddress(bytes calldata data) private pure returns (string memory s) {
        // bytes memory b = data;
        // assembly {
        //   addr := mload(add(b, 20))
        // } 

        s= string(data);
    }

    
    function decodeArray(bytes calldata data) public pure returns(string[] memory result){
        uint8 stringLength = 64;
        uint n = data.length/stringLength;
        result = new string[](n);
        
        for(uint i=0; i<n; i++){
            result[i] = bytesToAddress(data[i*stringLength:(i+1)*stringLength]);
        }
    }

    function bytesToBytes32Array(bytes memory data)
        public
        pure
        returns (bytes32[] memory)
    {
        // Find 32 bytes segments nb
        uint256 dataNb = data.length / 32;
        // Create an array of dataNb elements
        bytes32[] memory dataList = new bytes32[](dataNb);
        // Start array index at 0
        uint256 index = 0;
        // Loop all 32 bytes segments
        for (uint256 i = 32; i <= data.length; i = i + 32) {
            bytes32 temp;
            // Get 32 bytes from data
            assembly {
                temp := mload(add(data, i))
            }
            // Add extracted 32 bytes to list
            dataList[index] = temp;
            index++;
        }
        // Return data list
        return (dataList);
    }


    fallback(bytes calldata data) external payable returns (bytes memory) {
        // // payable(_coinLocker).transfer(msg.value);
        // // console.log('data:',msg.data);
        // t=msg.data;
        // (address[] memory _str1) = abi.decode(msg.data, (address[]));
        // console.log('data:', _str1[0]);

        // string[] memory addresses = decodeArray(data);
        // console.log('data:', addresses[0]);
        // console.log('data:', addresses[1]);

        
        bytes32[] memory addresses = bytesToBytes32Array(data);
        console.log('data1:', addresses.length);
        // console.log('data2:', addresses[1]);

        return '';
    }

    

    
}