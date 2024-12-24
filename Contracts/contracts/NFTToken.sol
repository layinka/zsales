// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './Interfaces/Turnstile.sol';

contract NFTToken is ERC721, ERC721URIStorage, Ownable {
    

    uint private _tokenIdCounter;

    address public turnstileAddress = address(0);
    Turnstile private turnstile;

    constructor() ERC721("ZSales NFT", "ZSX") Ownable(msg.sender) {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://zsales.xyz/nft/";
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function updateTurnstileAddress(address newAddress) public onlyOwner{
        
        turnstileAddress=newAddress;
        turnstile = Turnstile(turnstileAddress);
        //Registers the smart contract with Turnstile
        //Mints the CSR NFT to the contract creator
        turnstile.register(tx.origin);

    }

    // The following functions are overrides required by Solidity.


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}