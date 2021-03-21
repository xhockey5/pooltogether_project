const { deployMockContract } = require('ethereum-waffle')

const { expect } = require('chai')
const hardhat = require('hardhat')

const now = () => (new Date()).getTime() / 1000 | 0
const toWei = (val) => ethers.utils.parseEther('' + val)
const debug = require('debug')('ptv3:PeriodicPrizePool.test')

let overrides = { gasLimit: 9500000 }

  describe('Award ERC721 token to an address', () => {
    it('Allow the owner to award an NFT', async () => {
    [wallet, wallet2, wallet3] = await hardhat.ethers.getSigners()

    debug(`using wallet ${wallet.address}`)

    debug('deploying registry...')
    registry = await deploy1820(wallet)

    const foo = await hre.artifacts.readArtifact("MyHorse")
    const myhorse = await foo.deploy()
    await myhorse.deployed()
      await myhorse.awardWinner(0, "www.foo.com", 1234);
    })
  })
