// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require("fs");

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile 
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy

    const MyHorse = await ethers.getContractFactory("MyHorse");
    const myhorse = await MyHorse.deploy();
    await myhorse.deployed();
    console.log("myhorse deployed to: " + myhorse.address);

    const MyContract = await ethers.getContractFactory("MyContract");
    const mycontract = await MyContract.deploy(myhorse.address);
    await mycontract.deployed();
    console.log("mycontract deployed to: " + mycontract.address);

    const config = {
        myhorseAddress: myhorse.address,
        mycontractAddress: mycontract.address
    }

    fs.writeFileSync(".config.json", JSON.stringify(config, null, 2));

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
