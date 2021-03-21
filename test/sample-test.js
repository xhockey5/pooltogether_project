const { expect } = require("chai");
const assert = require('chai').assert;

function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
}

describe("Award a winner the NFT", function() {
    let accounts;
    let owner;
    let addr1;
    let foo;
    let myhorse;
    let _;
    let mycontract;
    beforeEach(async () => {
        accounts = await ethers.provider.listAccounts()
        owner = accounts[0]
        [_, addr1] = await ethers.getSigners()
        foo = await ethers.getContractFactory("MyHorse")
        myhorse = await foo.deploy()
        await myhorse.deployed()

        foo = await ethers.getContractFactory("MyContract")
        console.log(myhorse.address)
        mycontract = await foo.deploy(myhorse.address)
        await mycontract.deployed()
    });
  it("Should display the Award emitted event for minting an NFT", async function() {

    var tx = await myhorse.awardWinner(accounts[0], "localhost:8080/index.txt", 1234);
    rec = await tx.wait()
    var z = rec.events.filter((x) => {return x.event == "Award"})
    assert.isNotEmpty(z, "No event received")

  });
  it("Should not allow a non owner to award a token", async function() {

    await expect(myhorse.connect(addr1).awardWinner(owner, "localhost:8080/index.json", 1234)).to.be.reverted;

  });
  it("Place a bet on a horse", async function() {
      await mycontract.placeBet(0, {
        //value: ethers.utils.formatEther("10000000000000000000")
        value: ethers.utils.parseEther("10000000000")
      })
  });

});
