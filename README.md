
# Multi-Signature Wallet 🛡️

A secure, robust, and gas-efficient multi-signature wallet implemented in Solidity. This project allows multiple parties to collectively manage funds, requiring a minimum number of approvals before a transaction can be executed. It's built with the [Foundry](https://github.com/foundry-rs/foundry) framework for development, testing, and deployment.

## About The Project

A multi-signature (multi-sig) wallet is a type of digital wallet that requires two or more private keys to sign and authorize a transaction. The core idea is to enhance security by distributing control over funds among multiple participants (owners). This prevents a single point of failure and protects against unauthorized access.

This implementation provides a flexible and secure on-chain wallet where you can define a list of owners and a "threshold"—the number of approvals required to execute a transaction. It's ideal for DAOs, corporate treasuries, or any group needing to manage shared assets securely.

-----

## Key Features

  * **Customizable Threshold**: Define the exact number of owner approvals needed for a transaction.
  * **Transaction Lifecycle**: Full support for submitting, approving, revoking, canceling, and executing transactions.
  * **Event-Driven**: Emits detailed events for all significant actions (deposits, submissions, approvals, etc.) for easy off-chain monitoring.
  * **Security First**: Follows best practices, including the checks-effects-interactions pattern to prevent reentrancy attacks.
  * **Developer Friendly**: Built with Foundry and includes a comprehensive `Makefile` for a streamlined development workflow.
  * **Multi-Network Deployment**: Includes scripts and configurations for easy deployment to local networks (Anvil) and public testnets (Sepolia).

-----

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing.

### Prerequisites

You must have the **Foundry** development toolchain installed. If you don't, please follow the installation instructions [here](https://book.getfoundry.sh/getting-started/installation).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone <YOUR_REPOSITORY_URL>
    cd <YOUR_PROJECT_DIRECTORY>
    ```
2.  **Install dependencies:**
    This project uses `forge-std` and `foundry-devops`. Install them using the built-in `make` command, which runs `forge install`.
    ```sh
    make install
    ```

-----

## Usage & Commands

This project is managed through a `Makefile` that simplifies the entire development lifecycle.

### Environment Setup

For deployment to a live network like Sepolia, you need to create a `.env` file in the root directory and populate it with the necessary credentials.

Create a `.env` file:

```sh
touch .env
```

Add the following variables to your `.env` file:

```env
# Your Sepolia RPC URL from a provider like Infura or Alchemy
RPC_URL="https://sepolia.infura.io/v3/your-infura-project-id"

# The private keys of the wallet owners
PRIVATE_KEY1="0x..."
PRIVATE_KEY2="0x..."
# Add more keys if needed for your configuration

# Your Etherscan API key for contract verification
API_KEY="your-etherscan-api-key"
```

**Note**: The `Makefile` is pre-configured to load these variables.

### Makefile Commands

Here are the most common commands you will use:

| Command                 | Description                                                                                           |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| `make all`              | A full reset. Cleans the project, reinstalls dependencies, updates them, and builds the contracts.    |
| `make build`            | Compiles the smart contracts.                                                                         |
| `make test`             | Runs the unit and integration tests.                                                                  |
| `make snapshot`         | Generates a gas snapshot to track gas usage changes.                                                  |
| `make coverage`         | Runs tests and generates a code coverage report in the terminal.                                      |
| `make coverage-html`    | Generates a detailed HTML coverage report located in the `coverage-html` directory.                   |
| `make format`           | Formats the Solidity code using `forge fmt`.                                                          |
| `make anvil`            | Starts a local Anvil node for testing and development.                                                |
| `make deploy-anvil`     | Deploys the `MultiSigWallet` contract to the local Anvil network.                                     |
| `make fund-anvil`       | Sends 0.01 ETH to the most recently deployed contract on Anvil.                                       |
| `make deploy-sepolia`   | Deploys and verifies the `MultiSigWallet` contract on the Sepolia testnet. **(Requires `.env` file)** |
| `make fund-sepolia`     | Sends ETH to the most recently deployed contract on Sepolia. **(Requires `.env` file)**               |
| `make submit-sepolia`   | Submits a new transaction from owner 1 on Sepolia. **(Requires `.env` file)**                         |
| `make approve-sepolia1` | Approves the latest transaction with owner 1's key on Sepolia. **(Requires `.env` file)**             |
| `make approve-sepolia2` | Approves the latest transaction with owner 2's key on Sepolia. **(Requires `.env` file)**             |
| `make execute-sepolia`  | Executes the latest transaction (once the threshold is met) on Sepolia. **(Requires `.env` file)**    |

-----

## Local Development Workflow

Here’s a typical workflow for testing the contract on your local machine.

1.  **Start the Anvil chain** in a separate terminal window:

    ```sh
    make anvil
    ```

2.  **Deploy the contract** to your local Anvil chain:

    ```sh
    make deploy-anvil
    ```

    Take note of the contract address printed in the console.

3.  **Fund the wallet** with some test Ether:

    ```sh
    make fund-anvil
    ```

4.  **Interact with the contract**: Use `cast` or other scripts to submit, approve, and execute transactions.

-----

## Testnet Deployment & Interaction (Sepolia)

This example assumes the default `HelperConfig.s.sol` configuration: **3 owners** and a **threshold of 2**.

1.  **Set up your `.env` file** with your `RPC_URL`, at least two `PRIVATE_KEY`s, and an `API_KEY`.

2.  **Deploy the wallet** to Sepolia:

    ```sh
    make deploy-sepolia
    ```

3.  **Fund the wallet** so it can execute transactions:

    ```sh
    make fund-sepolia
    ```

4.  **Submit a transaction** (e.g., sending 0.01 ETH to a target address). This is done by `PRIVATE_KEY1`:

    ```sh
    make submit-sepolia
    ```

5.  **Approve the transaction**. Since the threshold is 2, we need two separate owners to approve it.

      * Approve with owner 1 (`PRIVATE_KEY1`):
        ```sh
        make approve-sepolia1
        ```
      * Approve with owner 2 (`PRIVATE_KEY2`):
        ```sh
        make approve-sepolia2
        ```

6.  **Execute the transaction**. Now that the threshold (2 approvals) has been met, any owner can execute the transaction.

    ```sh
    make execute-sepolia
    ```

    Success\! The funds have been moved according to the approved transaction. 🎉

-----

## Contract Overview

The project is centered around the `MultiSigWallet.sol` contract.

  * **State Variables**:

      * `owners`: An array of addresses that co-own the wallet.
      * `isOwner`: A mapping for efficient `O(1)` owner lookups.
      * `threshold`: The immutable number of approvals required for execution.
      * `transactions`: An array storing all proposed transactions.
      * `approved`: A nested mapping (`txId` =\> `owner` =\> `bool`) to track approvals.

  * **Core Functions**:

      * `constructor`: Initializes the wallet with a set of owners and a threshold.
      * `submit`: Allows an owner to propose a new transaction.
      * `approve`: Allows an owner to approve a pending transaction.
      * `revoke`: Allows an owner to withdraw their approval.
      * `cancel`: Allows an owner to cancel a transaction if it hasn't met the threshold.
      * `execute`: Executes a transaction if it has met the approval threshold.

  * **Scripts**:

      * `DeployMultiSigWallet.s.sol`: Handles the deployment logic.
      * `HelperConfig.s.sol`: Manages network-specific configurations (like owners and threshold) for seamless multi-chain deployment.
      * `Interactions.s.sol`: A collection of scripts to interact with the deployed contract (deposit, submit, approve, etc.).

-----

## Contributing

Contributions are welcome\! If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the "enhancement" tag.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

-----

## License

This project is distributed under the MIT License. See `LICENSE` for more information.