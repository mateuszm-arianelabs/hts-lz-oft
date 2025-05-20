import { task } from 'hardhat/config'

import { types } from '@layerzerolabs/devtools-evm-hardhat'

task('oft:mint', 'Mints new tokens via the MyOFT contract')
    .addParam('to', 'Address to receive minted tokens', undefined, types.string)
    .addParam('amount', 'Amount of tokens to mint (in token units)', undefined, types.string)
    .setAction(async (taskArgs, { ethers, deployments }) => {
        const { to, amount } = taskArgs
        // Fetch the deployment info
        const { address: contractAddress, abi } = await deployments.get('MyOFT')
        // Use the first signer (must be the owner)
        const [owner] = await ethers.getSigners()
        // Attach to your deployed contract
        const oft = new ethers.Contract(contractAddress, abi, owner)
        // Read token decimals so we can parse the user‐supplied amount
        const decimals = await oft.decimals()
        const mintAmount = ethers.utils.parseUnits(amount, decimals)
        // Call mint()
        const tx = await oft.mint(to, mintAmount)
        console.log(`🚀 Mint transaction sent: ${tx.hash}`)
        await tx.wait()
        console.log(`✅ Successfully minted ${amount} token(s) to ${to}`)
    })
