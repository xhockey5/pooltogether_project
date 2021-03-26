// SPDX-License-Identifier: GPL-3.0
    /*
    mapping(uint => uint16) winningHorses;
    winningHorses[i] = horseIdx;
    function redeem(raceIdx) {
        winningHorse = winningHorses[raceIdx]
        this.transfer(bets[winningHorse][msg.sender])
    }
    function redeemMultiple(raceIdxArray) {
        amt = 0;
        for i in raceIdxArray {
            winningHorse = winningHorses[raceIdx]
            amt += bets[winningHorse][msg.sender])
        }
        this.transfer(amt)
    }
    */
pragma solidity ^0.7.0;

import "sortition-sum-tree-factory/contracts/SortitionSumTreeFactory.sol";
import "@pooltogether/uniform-random-number/contracts/UniformRandomNumber.sol";
import "./horse.sol";
import "hardhat/console.sol";

interface foo {
    function awardWinner(address, string memory, bytes32) external returns(uint256);
}

// XXX: Future improvement to create a better user interface
// XXX: subgraph (https://www.chainshot.com/article/the-graph-3-16-21)

contract MyContract {

    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;
    uint256 constant private MAX_TREE_LEAVES = 5;

    uint balance;
    // race index, horse index, address of person placing bet, amount of bet
    mapping(uint => mapping(uint16 => mapping(address => uint))) bets;


    mapping(address => uint) public winnings;
    uint16 NUM_HORSES = 10;
    bytes32 seed = 0;
    address public horse;
    address public owner = msg.sender;
    uint public raceIdx = 0;

    constructor(address _horse) {
        // Use the counterfactual stuff later
        horse = _horse;
        genTrees();
    }

    function incrementRace() private {
        raceIdx += 1;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function updateHorseAddr(address addr) isOwner public {
        horse = addr;
    }

    function getSeedNum() private {
        // change later to accept "last race block or something predictable"
        if (seed == 0) {
            seed = blockhash(block.number - 1);
        }
    }

    function genTrees() private {
        for (uint16 i=0; i < NUM_HORSES; i++) {
            sortitionSumTrees.createTree(getHorse(i), MAX_TREE_LEAVES);
        }
        // Create a seperate sortitionSumTree that includes all the horses in one tree
        sortitionSumTrees.createTree("all_horses", MAX_TREE_LEAVES);
    }

    // @notice Returns the horses chance of winning.
    function chanceOf(uint16 horseIdx) external view returns (uint256) {
        // 10 horses, places 1 ticket on horse A and 10 tickets on horse B
        // idx is the index of the horse
        uint total = 0;
        uint totalForIdx = 0;
        uint horseTotal = 0;
        for (uint16 i=0; i < NUM_HORSES; i++) {
            totalForIdx = sortitionSumTrees.total(getHorse(uint16(i)));
            total += totalForIdx;
            if (i == horseIdx) {
                horseTotal = totalForIdx;
            }
        }

        // Multiple by a hundred to get the percentage back
        horseTotal = horseTotal * 100;
        return horseTotal / total;
    }

    // The percentage of the pot a user will get if a given horse wins
    // XXX: This has a rounding error, not sure how to fix that right now
    function percentPayoffWinningHorse(uint16 horseIdx) isValidHorse(horseIdx) view public returns(uint) {
        uint bet = getBet(horseIdx);
        uint total = sortitionSumTrees.total(getHorse(uint16(horseIdx)));
        uint percent_chance = (bet*100) / total;
        return percent_chance;
    }

    // @notice Selects a user using a random number.  The random number will be uniformly bounded to the ticket totalSupply.
    // @param randomNumber The random number to use to select a user.
    // @return The winner
    function drawNFT(uint256 randomNumber, uint16 winningHorseIdx) isValidHorse(winningHorseIdx) public view returns (address) {
        uint256 bound = sortitionSumTrees.total(getHorse(uint16(winningHorseIdx)));
        address selected;
        uint256 token;
        if (bound == 0) {
            selected = address(0);
        } else {
            token = UniformRandomNumber.uniform(randomNumber, bound);
            selected = address(uint256(sortitionSumTrees.draw(getHorse(uint16(winningHorseIdx)), token)));
        }
        return selected;
    }

    function getBet(uint16 idx) public view returns(uint amt) {
        amt = sortitionSumTrees.stakeOf(getHorse(idx), bytes32(uint256(msg.sender)));
    }

    // Place a bet on a given horse index number
    function placeBet(uint16 idx) isValidHorse(idx) public payable returns(uint){
        // idx has to be less then NUM_HORSES
        bets[raceIdx][idx][msg.sender] = msg.value;
        balance += msg.value;
        sortitionSumTrees.set(getHorse(idx), msg.value, bytes32(uint(msg.sender)));
        sortitionSumTrees.set("all_horses", msg.value, bytes32(uint(idx)));
        return 0;
    }

    function getHorse(uint16 idx) isValidHorse(idx) public view returns(bytes32) {
        return keccak256(abi.encodePacked(seed, idx));
    }

    // mint once we have the attributes/data
    function mintToken(address winner, string memory tokenURI, bytes32 horseAttr) private {
        // we'll have to call awardWinner on the horse.sol contract
        bytes memory payload = abi.encodeWithSignature("awardWinner(address,string,bytes32)", winner, tokenURI, horseAttr);
        address(horse).call(payload);
    }

    function randomNumber() private view returns(bytes32 blockHash) {
        return blockhash(block.number - 1);
    }

    function getWinningHorse(uint _randomNumber) private view returns(uint16 _horseIdx) {
        uint token = UniformRandomNumber.uniform(_randomNumber, balance);
        _horseIdx = uint16(uint(sortitionSumTrees.draw("all_horses", token)));
    }

    // helper function to just make sure things are working
    function forceWinner(uint _randomNumber) public returns(address){
        //uint _randomNumber = uint(randomNumber());
        uint16 horseIdx = getWinningHorse(_randomNumber);
        address winner = drawNFT(_randomNumber, horseIdx);
        mintToken(winner, "www.abc.com", getHorse(horseIdx));
        // XXX: Determine how to split profits evenly
        // XXX: For now just send the entire amount to a single winner
        payable(winner).transfer(address(this).balance);
        incrementRace();

        return winner;
    }

    modifier isValidHorse(uint16 idx) {
        require(idx < NUM_HORSES, "Horse index out of range");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
}
