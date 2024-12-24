
// import { ethers } from "hardhat";
// import { expect } from "chai";

// describe("Presale", function () {
//     let presale;
//     let token;
//     let baseCurrency;
//     let owner;
//     let addr1;
//     let addrs;

//     const baseCurrencyDecimals =4

//     beforeEach(async function () {
//         [owner, addr1, ...addrs] = await ethers.getSigners();

//         const BaseCurrency = await ethers.getContractFactory("DecimalToken"); // Replace with your token contract
//         baseCurrency = await BaseCurrency.deploy(baseCurrencyDecimals);

//         const Token = await ethers.getContractFactory("DecimalToken"); // Replace with your token contract
//         token = await Token.deploy(6);

//         const Presale = await ethers.getContractFactory("Presale");
//         presale = await Presale.deploy(token.address, baseCurrency.address, 100); // 100 rate, replace with your base currency and rate
//         await presale.deployed();
//     });

//     // it("should buy tokens correctly", async function () {
//     //     const baseCurrencyAmount = ethers.utils.parseUnits("1000", baseCurrencyDecimals); // 1 unit of base currency
//     //     const tokensToBuy = baseCurrencyAmount.mul(100); // Assuming rate is 100

//     //     // Record the initial token balance of the buyer
//     //     const initialTokenBalance = await token.balanceOf(addr1.address);

//     //     // Make the purchase
//     //     await token.approve(presale.address, baseCurrencyAmount);
//     //     await baseCurrency.approve(presale.address, baseCurrencyAmount);
//     //     // await presale.buyTokens(baseCurrencyAmount);

//     //     // // Record the final token balance of the buyer
//     //     // const finalTokenBalance = await token.balanceOf(addr1.address);

//     //     // // Assert that the buyer received the correct amount of tokens
//     //     // expect(finalTokenBalance.sub(initialTokenBalance)).to.equal(tokensToBuy);

//     //     const result = await presale.calcRates(baseCurrencyAmount);
//     //     console.log('Result: ', result)
//     //     for(let i=0; i<3;i++){
//     //         console.log(i, '6 digits: ', ethers.utils.formatUnits(result[i],6))
//     //         console.log(i, '18 digits: ', ethers.utils.formatUnits(result[i],18))
//     //     }
//     // });

//     it('multiply well', async ()=>{
//         let result = await presale.multiply(ethers.utils.parseUnits('10', 18),18, ethers.utils.parseUnits('20', 18), 18 )
        
//         const aDecimal = 18
//         const bDecimal = 6;

//         result = await presale.multiply(ethers.utils.parseUnits('10.24', aDecimal),aDecimal, ethers.utils.parseUnits('20',bDecimal), bDecimal )
//         console.log(' 10 * 20 ', ethers.utils.formatUnits(result, 18))
//         console.log(' 10 * 20 : ETH:  ', (+ethers.utils.formatEther(result)) / 1e18  ) //Divide by 1e18 to get unnormalized answer


//         // console.log(' 10 * 20 : ETH:  ', ((+ethers.utils.formatUnits(result, 6)) / 1e18)/ 1e12  ) //to toknb decimal

        
//     })
// });
