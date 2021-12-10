import { ethers } from "hardhat";
import { DotsNFT } from "../typechain";

async function main() {
  const dotsFactory = await ethers.getContractFactory("DotsNFT");
  const dots = (await dotsFactory.deploy()) as DotsNFT;

  for (let i = 0; i < 1000; i++) {
    const mintTx = await dots.mint(1);
    await mintTx.wait();
    const uri = await dots.tokenURI(i);
    console.log(uri);
    console.log("--------------");
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
