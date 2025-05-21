# Layer Zero (HTS Connector) usage with Hedera

This repo contains a test setup for bridging a fungible HTS token from Hedera to another chain (Avalanche Fuji) using LayerZero’s HTS Connector.
Contracts are in `contracts/`, deploy scripts in `deploy/`, and token send/mint scripts in `tasks/`.

## ⚠️ Status
At the moment, the HTS Connector implementation with LayerZero and Hedera does not work.


- Everything deploys fine, config is correct, scripts run, but for some reason the transfer doesn’t work.

- When sending from Hedera, the transaction “succeeds” locally but never gets picked up on LayerZeroScan, it just stays in indexing forever.

- When sending from Avalanche, the transaction goes all the way to execution but fails in the final step, inside lzReceive() on Hedera.

-  on the call trace on Hashscan, the failure is because the HTS Connector can’t mint the token — you get unable to mint token.