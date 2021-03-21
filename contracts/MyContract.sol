// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "sortition-sum-tree-factory/contracts/SortitionSumTreeFactory.sol";
import "@pooltogether/uniform-random-number/contracts/UniformRandomNumber.sol";
import "./horse.sol";

interface foo {
    function awardWinner(address, string memory, uint256) external view;
}

contract MyContract {

    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    // Ticket-weighted odds
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;
    uint256 constant private MAX_TREE_LEAVES = 5;

    uint balance;
    mapping(bytes32 => mapping(address => uint)) bets;
    uint16 NUM_HORSES = 10;
    bytes32 seed = 0;
    address horse;
    address owner = msg.sender;

    constructor(address _horse) {
        // Use the counterfactual stuff later
        horse = _horse;
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

        return horseTotal / total;
    }

    // XXX: how much the sender would get if their horse wins not sure if this is a percent or what...
    function payoffAmount(uint16 horseIdx) isValidHorse(horseIdx) public returns(uint) {
        return sortitionSumTrees.stakeOf(getHorse(uint16(horseIdx)), bytes32(uint256(msg.sender)));
    }

    // @notice Selects a user using a random number.  The random number will be uniformly bounded to the ticket totalSupply.
    // @param randomNumber The random number to use to select a user.
    // @return The winner
    function drawNFT(uint256 randomNumber, uint16 winningHorseIdx) isValidHorse(winningHorseIdx) public returns (address) {
        uint256 bound = sortitionSumTrees.total(getHorse(uint16(winningHorseIdx)));
        address selected;
        if (bound == 0) {
            selected = address(0);
        } else {
            uint256 token = UniformRandomNumber.uniform(randomNumber, bound);
            selected = address(uint256(sortitionSumTrees.draw(getHorse(uint16(winningHorseIdx)), token)));
        }
        return selected;
    }

    function placeBet(uint16 idx) isValidHorse(idx) public payable returns(uint){
        // idx has to be less then NUM_HORSES
        bets[getHorse(idx)][msg.sender] = msg.value;
        return 0;

        //balance += msg.value;
        //sortitionSumTrees.set(getHorse(idx), msg.value, bytes32(uint256(msg.sender)));
        //sortitionSumTrees.set("all_horses", msg.value, bytes32(uint(idx)));
    }

    function getHorse(uint16 idx) isValidHorse(idx) public view returns(bytes32) {
        return keccak256(abi.encodePacked(seed, idx));
    }

    // mint once we have the attributes/data
    function mintToken(address winner, string memory tokenURI, uint horseAttr) private {
        // we'll have to call awardWinner on the horse.sol contract
        foo(horse).awardWinner(winner, tokenURI, horseAttr);
    }

    function randomNumber() private returns(bytes32 blockHash) {
        return blockhash(block.number - 1);
    }

    function getWinningHorse(uint _randomNumber) private returns(uint16 _horseIdx) {
        uint token = UniformRandomNumber.uniform(_randomNumber, NUM_HORSES);
        _horseIdx = uint16(uint(sortitionSumTrees.draw("all_horses", token)));
    }

    // helper function to just make sure things are working
    function forceWinner(uint _randomNumber) public {
        uint16 horseIdx = getWinningHorse(_randomNumber);
        address winner = drawNFT(_randomNumber, horseIdx);
        mintToken(winner, "www.abc.com", uint(getHorse(horseIdx)));
        // XXX: Determine how to split profits evenly
        // XXX: For now just send the entire amount to a single winner
        payable(winner).transfer(address(this).balance);
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
