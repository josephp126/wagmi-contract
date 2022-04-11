const { task } = require("hardhat/config");
const { getAccount } = require("./helpers");


task("check-balance", "Prints out the balance of your account").setAction(async function (taskArguments, hre) {
	const account = getAccount();
	console.log(`Account balance for ${account.address}: ${await account.getBalance()}`);
});

task("deploy", "Deploys the NFT.sol contract").setAction(async function (taskArguments, hre) {
	const contractFactory = await hre.ethers.getContractFactory("NFT", getAccount());
	const contract = await contractFactory.deploy();
	console.log(`Contract deployed to address: ${contract.address}`);
});
