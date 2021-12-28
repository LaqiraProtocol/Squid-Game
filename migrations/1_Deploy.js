const fs = require('fs');

const LaqiraToken = artifacts.require("ERC20TokenMock");
const SquidGameToken = artifacts.require("ERC20TokenMock");
const SquidGameContract = artifacts.require("SquidGame");

require('dotenv').config()

module.exports =  async function (deployer, network) {
   await deployer.deploy(LaqiraToken, 'LaqiraToken', 'LQR', process.env.INITIAL_SUPPLY)
   await deployer.deploy(SquidGameToken, 'SquidGameToken', 'SQUID', process.env.INITIAL_SUPPLY)
   
   const LQR = await LaqiraToken.deployed()
   const SQUID = await SquidGameToken.deployed()

   await deployer.deploy(SquidGameContract, LQR.address, SQUID.address)

   const SquidGame = await SquidGameContract.deployed()

   let data = `network: ${network}\nLaqiraToken address: ${LQR.address} \nSquidGameToken address: ${SquidGameToken.address} \nSquidGame(Main): ${SquidGame.address}` 
   fs.writeFileSync("information.txt", data);
};