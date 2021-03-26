const { expect } = require("chai");
const assert = require('chai').assert;

function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
}

horseAscii = "\033[96m           ,--,\r\n     _ ___\/ \/\\|\r\n ,;\'( )__, )  ~\r\n\/\/  \/\/   \'--; \r\n\'   \\     | ^\r\n     ^    ^\033[0m"
console.log(horseAscii)
horseAscii2 = "\033[92m   _____,,;;;`;       ;\';;;,,_____\r\n,~(  )  , )~~\\|       |\/~~( ,  (  )~;\r\n\' \/ \/ --`--,             .--\'-- \\ \\ `\r\n \/  \\    | \'             ` |    \/  \\ \033[0m"
console.log(horseAscii2)


describe("Award a winner the NFT", function() {
    let accounts;
    let owner;
    let ownerSigner
    let addr1;
    let foo;
    let myhorse;
    let _;
    let mycontract;
    let a;
    beforeEach(async () => {
        accounts = await ethers.provider.listAccounts()
        owner = accounts[0]
        signers = await ethers.getSigners()
        ownerSigner = signers[0];
        addr1 = signers[1]

        foo = await ethers.getContractFactory("MyHorse")
        myhorse = await foo.deploy()
        await myhorse.deployed()

        foo = await ethers.getContractFactory("MyContract")
        mycontract = await foo.deploy(myhorse.address)
        await mycontract.deployed()
    });

  it("Should display the Award emitted event for minting an NFT", async function() {

    var tx = await myhorse.awardWinner(accounts[0], "localhost:8080/index.txt", ethers.utils.formatBytes32String("1234"));
    var rec = await tx.wait()
    var z = rec.events.filter((x) => {return x.event == "Award"})
    assert.isNotEmpty(z, "No event received")

  });

  it("Should not allow a non owner to award a token", async function() {
    await expect(myhorse.connect(addr1).awardWinner(owner, "localhost:8080/index.json", 1234)).to.be.reverted;
  });

  it("Place a bet on a horse", async function() {
      betAmount = 10
      await mycontract.placeBet(0, {
        value: ethers.utils.parseEther(betAmount.toString(), "ether")
      })
      let bet = await mycontract.getBet(0);
      assert(ethers.utils.formatEther(bet) == betAmount)

      // Now for Addr 1
      z = await mycontract.connect(addr1)
      await z.placeBet(0, {
        value: ethers.utils.parseEther("5", "ether")
      })
      bet = await z.getBet(0);
      assert(ethers.utils.formatEther(bet) == 5)

      let chance_to_win = await mycontract.percentPayoffWinningHorse(0);
      chance_to_win = parseInt(chance_to_win);
      let balance = await mycontract.getBalance();
      balance = parseInt(balance);
      let payoff = (chance_to_win / 100) * balance;
      payoff = ethers.utils.formatEther(BigInt(payoff))
      assert(payoff == 9.9, "Expected payout is wrong")

  });
  it("Update the address of the horse NTF contract", async function() {
      let oldHorseAddr = await mycontract.horse();
      await mycontract.updateHorseAddr("0x1111111111111111111111111111111111111111");
      let newHorseAddr = await mycontract.horse();
      assert(newHorseAddr == "0x1111111111111111111111111111111111111111")
  });
  it("Dont allow the address update of the horse NTF contract from a non owner", async function() {
      z = await mycontract.connect(addr1)
      await expect(z.updateHorseAddr("0x1111111111111111111111111111111111111111")).to.be.reverted;
  });
  it("Dont allow a bet on an invalid horse", async function() {
      await expect(
          mycontract.placeBet(20, {
            value: ethers.utils.parseEther("5", "ether")
          })
        ).to.be.reverted;
  });
  it("Get a horses chance of winning", async function() {
      betAmount = 10
      await mycontract.placeBet(0, {
        value: ethers.utils.parseEther(betAmount.toString(), "ether")
      })

      betAmount = 90
      await mycontract.placeBet(1, {
        value: ethers.utils.parseEther(betAmount.toString(), "ether")
      })

      let chance = await mycontract.chanceOf(0);
      assert(chance == 10, "Horses percent chance to win is wrong")
  });
  it("Force a winner with only one horse being bet on with 2 people", async function() {
      betAmount = 10
      await mycontract.placeBet(0, {
        value: ethers.utils.parseEther(betAmount.toString(), "ether")
      })
      let bet = await mycontract.getBet(0);

      // Now for Addr 1
      z = await mycontract.connect(addr1)
      await z.placeBet(0, {
        value: ethers.utils.parseEther("5", "ether")
      })
      bet = await z.getBet(0);

      // The sortition tree draw function is deterministic based on the random number given
      // currently with the owner better 10 ether and addr1 betting 5 ether it will cause
      //    - The winner to be addr1 using a random number of 1 ether
      //    - The winner to be the owner using a random number of 2 ether
      await myhorse.updateOwner(mycontract.address)
      // Check the return value and make sure forceWinner returns the expected winner
      let winner = await mycontract.callStatic.forceWinner(ethers.utils.parseEther("1", "ether"))
      assert(winner == addr1.address, "Unexpected winner")
      // Do a real call of forceWinner and watch for the emitted event
      let topic_id = ethers.utils.id("Award(address,uint256,bytes32)")
      let tx = await mycontract.forceWinner(ethers.utils.parseEther("1", "ether"))
      let rec = await tx.wait()
      let found = false;
      rec.events.filter((x) => {
          if (x.topics.includes(topic_id)) {
              found = true
          }
      })
      assert(found == true, "No event received")

      // Check the return value and make sure forceWinner returns the expected winner
      winner = await mycontract.callStatic.forceWinner(ethers.utils.parseEther("2", "ether"))
      assert(winner == owner, "Unexpected winner")
      await mycontract.forceWinner(ethers.utils.parseEther("2", "ether"))

      // Do a real call of forceWinner and watch for the emitted event
      tx = await mycontract.forceWinner(ethers.utils.parseEther("1", "ether"))
      rec = await tx.wait()
      found = false;
      rec.events.filter((x) => {
          if (x.topics.includes(topic_id)) {
              found = true
          }
      })
      assert(found == true, "No event received")
  });
  it("Force a winner with two horses being bet on with 2 people", async function() {
      betAmount = 10
      await mycontract.placeBet(0, {
        value: ethers.utils.parseEther(betAmount.toString(), "ether")
      })
      let bet = await mycontract.getBet(0);

      // Now for Addr 1
      z = await mycontract.connect(addr1)
      await z.placeBet(1, {
        value: ethers.utils.parseEther("5", "ether")
      })
      bet = await z.getBet(0);

      let topic_id = ethers.utils.id("Award(address,uint256,bytes32)")
      let horseOwner = await myhorse.updateOwner(mycontract.address)
      // The sortition tree draw function is deterministic based on the random number given
      // currently with the owner better 10 ether and addr1 betting 5 ether it will cause
      //    - The winner to be the owner using a random number of 0 ether - the winner will be horse 0
      //    - The winner to be addr1 using a random number of 2 ether - the winner will be horse 1
      // Make sure we set the owner address in the horse contract
      //
      // Check the return value and make sure forceWinner returns the expected winner
      let winner = await mycontract.callStatic.forceWinner(0)
      assert(winner == owner, "Unexpected winner")

      // Do a real call of forceWinner and watch for the emitted event
      let tx = await mycontract.forceWinner(0)
      let rec = await tx.wait()
      let found = false;
      rec.events.filter((x) => {
          if (x.topics.includes(topic_id)) {
              found = true
          }
      })
      assert(found == true, "No event received")

      // Check the return value and make sure forceWinner returns the expected winner
      winner = await mycontract.callStatic.forceWinner(2)
      assert(winner == addr1.address, "Unexpected winner")

      // Do a real call of forceWinner and watch for the emitted event
      tx = await mycontract.forceWinner(2)
      rec = await tx.wait()
      found = false;
      rec.events.filter((x) => {
          if (x.topics.includes(topic_id)) {
              found = true
          }
      })
      assert(found == true, "No event received")
  });
});
