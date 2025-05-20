import assert from 'assert'

import { type DeployFunction } from 'hardhat-deploy/types'

const contractName = 'ExampleHTS'

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)
    const endpointV2Deployment = await hre.deployments.get('EndpointV2')

    console.log({ endpointV2Deployment })

    try {
        const { address } = await deploy(contractName, {
            from: deployer,
            args: [
                'ExampleHTS', // name
                'EHTS', // symbol
                endpointV2Deployment.address, // LayerZero's EndpointV2 address
                deployer, // owner
            ],
            log: true,
            skipIfAlreadyDeployed: false,
            gasLimit: 15_000_000,
            value: hre.ethers.utils.parseUnits('15', 'ether'),
        })

        console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
    } catch (error) {
        console.error(error)
        throw error
    }
}

deploy.tags = [contractName]

export default deploy
