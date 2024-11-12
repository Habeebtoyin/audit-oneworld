# Cookbook.dev

## Find any smart contract, build your project faster

### Get ready-to-use Foundry projects directly from https://www.cookbook.dev

<p>
  <strong>Please follow these steps, if you all ready have Foundry setup ignore steps 1 and 2</strong>
</p>

<p>
  <strong> Step 1: Install Rust</strong>
  https://doc.rust-lang.org/book/ch01-01-installation.html
</p>

<p>
  <strong> Step 2: Install Foundry</strong>
  https://book.getfoundry.sh/getting-started/installation#using-foundryup
</p>

<p>
  <strong> Step 3: Build</strong>
  Please run the command below to build your contracts
  <code>
    forge build
  </code>
  If you get a stack to deep error try running the command below
  <code>
    forge build --via-ir 
  </code> 
</p>

<p>
  <strong> Step 4: Test</strong>
  Please run the command below to test your contracts, the given tests are examples please generate your own.
  <code>
    forge test
  </code>
</p>

<p>
  <strong> Step 5: Deploy</strong>
  First populate the .env file with your enviroment variable values.
  Please run the command below in your terminal to define your enviroment variables globally and deploy your contracts. The given script contract is an example please generate your own.
  <code>
    source .env
  </code>
  Then run the command below to deploy your contracts, make sure to replace the CONTRACT_FILENAME with the contract script file name and the CONTRACT_NAME with the script contract's name.
  <code>
    forge script script/CONTRACT_FILENAME:CONTRACT_NAME --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv

    Example: forge script script/contract.s.sol:ContractScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
  </code>
</p>

#### Example Contracts and Projects

- [Simple Token](https://www.cookbook.dev/contracts/simple-token)
- [Azuki EFC721A NFT](https://www.cookbook.dev/contracts/Azuki-ERC721A-NFT-Sale)
- [Uniswap Labs](https://www.cookbook.dev/profiles/Uniswap-Labs)
- [Nouns DAO](https://www.cookbook.dev/profiles/Nouns-DAO)
- [OpenSea](https://www.cookbook.dev/profiles/opensea)

[Search for 100s of other contracts](https://www.cookbook.dev/search?q=&categories=Primitives,Protocols&sort=popular&filter=&page=1)
