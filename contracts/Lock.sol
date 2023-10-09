// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// INTERNAL IMPORT FOR NFT OPENZIPLINE
import "@openzeppelin/contracts/utils/Counters.sol";// permet de gérer les compteurs, ce qui est utile pour suivre le nombre de NFT mintés(créer)
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // permet de stocker l'URI des métadonnés de chaque NFT, qui sont les infos telles que nom, description ou image du NFT.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Contrat de base, implémente la norme ERC721

import "hardhat/console.sol";

contract NFTMarketPlace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.0025 ether;

    address payable owner;

    mapping (uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 tokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner {
        required(
            msg.sender == owner,
            "only owner of the market place can change the listing price"
            );
            _;
    }

    constructor() ERC721("NTF Metaverse Token", "MYNFT") {
        owner == payable(msg.sender);
    }

    function updateListingPrice(uint256 _listingPrice) 
        public 
        payable 
        onlyOwner
    {
        listingPrice = _listingPrice
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // let create NFT token function

    function createToken(string memory tokenURI, uint256 price) public payable returns(uint256){
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    // creating market item

    function createMarketItem(uint256 tokenId, uint256 price) private {
        required(price > 0, "price must be at lest 1");
        required(msg.value == listingPrice, "price must be equal to listing price")

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(
            tokenId, 
            msg.sender, 
            address(this), 
            price, 
            false
        );
    }

    // Function for resale token
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(idMarketIem[tokenId].owner == msg.sender, "only itme owner can perform this operation");

        require(msg.value == listingPrice, "Price must be equal to listing");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // function createmarketsale

    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;

        require(
            msg.value == price, 
            "please submit the asking price in order to complete the purchase"
        );

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);

        payable(owner)._transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    // Getting unsold nft data
    function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0, i < itemCount; i++){
            if(idMarketItem[i+1].owner == address(this)) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentIndex;
                currentIndex += 1;
            }
        }
        return items;
    }


    // puchase item
    function fetchMyNFT() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currntId = i + 1;
                MarketItem storage currentItem = idMarketItem[currntId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //SINGULE USER ITEMS
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
    }    

}
