import { ethers, run } from "hardhat";
import { DotsNFT } from "../typechain";

async function main() {
  const dotsFactory = await ethers.getContractFactory("DotsNFT");
  const dots = (await dotsFactory.deploy()) as DotsNFT;

  console.log(`Address ${dots.address}`);

  await new Promise((resolve) => setTimeout(resolve, 45000));

  await run("verify:verify", {
    address: dots.address,
    constructorArguments: [],
    contract: "contracts/DotsNFT.sol:DotsNFT",
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
