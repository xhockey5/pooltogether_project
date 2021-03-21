// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
/*
Deposit USDC into pool
depositTo (USDC -> pool)
receive pool tokens
spend pool tokens to place bets - send pool tokens to horse contract

Feature:
    - Keep track of horse index bet that was used by an address last race and
      keep that index (let it ride) by default (they can call placeBet to place their bet on a different horse)
    - Make users deposit AND place bet

[My contract -> Pool together contract] - this will ensure a bet is place when they deposit USDC and then my contract
will forward the request to the group of pooltogether contracts

I was using multiple winners but i dont want to do that anymore
the "SingleRandomWinner.sol" should pick a winner and then call my horse contract to mint and award the NFT
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
contract MyHorse is ERC721 {
    /*
    enum attitudes = {
        Aggressive,
        Passive,
        Snarky,
        Wily,
        Sneaky,
        Shifty,
        Shrewd,
        Sly,
        Astute,
        Cunning,
        Deceitful,
        Greasy,
        Sharp,
        Slick,
        Tricky,
        Playful,
        Nonchalant,
        Cool,
        Frank,
        Honest,
        Social,
        Aloof,
        Fearful
    }
    enum coatColors {
        YellowDun,
        RedDun,
        MouseGrey,
        Grey,
        DappleGrey,
        FleaBitten,
        RoseGrey,
        Bay,
        Chestnut,
        BloodBay,
        DarkBay,
        BlackBay,
        LiverChestnut,
        Sabino,
        Tobiano,
        SplashWhite,
        FrameOvero,
        Palomino,
        Cremello,
        BuckskinDun,
        Perlino,
        ClassicChampagne,
        GoldChampagne,
        AmberChampagne,
        WhiteChampagne,
        BayRoan,
        RedRoan,
        BlueRoan,
    }
    */

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event Award(address addr, uint newItemId, uint horseAttr);

    address owner = msg.sender;
    constructor() ERC721("Horse", "HORSE") {}

    function awardWinner(address winner, string memory tokenURI, uint horseAttr) public allowed returns(uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(winner, newItemId);
        _setTokenURI(newItemId, tokenURI);
        
        emit Award(winner, newItemId, horseAttr);
        return newItemId;
    }

    modifier allowed() {
        require(msg.sender == owner, "Only the owner of the contract can award a winner");
        _;
    }
}
