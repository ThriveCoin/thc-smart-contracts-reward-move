# thc-smart-contracts-reward-move
ThriveCoin reward claiming smart contracts for SUI network

## Prequises

This project requires the following software dependencies:
- rust
- cargo
- sui

All of these can be installed by following instructions under:
https://docs.sui.io/guides/developer/getting-started/sui-install

## Setup

Setup js dependencies via:
```
npm i
```

Then run build cmd:
```
npm run build
```

## Dev deployment

First ensure that you're running sui client under devnet:
```
sui client envs # check if devnet is present

# if not add the network
sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443

# switch to devnet
sui client switch --env devnet
```

Then get the active address and send some funds to it via faucet:
```
# get address
sui client active-address

# get funds
curl --location --request POST 'https://faucet.devnet.sui.io/v1/gas' \
--header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "0x6f94e7051ad3a7c799fd913b22e06f076ce21932d618f3f0e661cf2cd56760bb"
    }
}'
```

Then confirm funds:
```
sui client gas
```

After this go to `thrivecoin` directory and deploy the package:
```
sui client publish --gas-budget <gas_limit> --json
```

Upon deployment you can check your tx on explorer and get necessary object ids:
```
https://suiscan.xyz/devnet/tx/<tx_digest>
```

Then you can test adding a reward:
```
sui client call --package <package_address> --module reward --function add_reward --args <writer_role_address> <reward_ledger_address> <recipient_address> <amount> --gas-budget <gas_limit>

# example call
sui client call --package 0x37aa7d5e387d3be357af9465d5a0d39c968e00ef71c5caaae714bb5e1b63b685 --module reward --function add_reward --args 0x05cf79a159452ee34719ae7f65efd56b24b902bc64b607b4e4a53e9a66af2ce4 0xac527de0c77ec36333f04b42ac93492feedbf3464e4c0114bed350cceeb89423 0x6f94e7051ad3a7c799fd913b22e06f076ce21932d618f3f0e661cf2cd56760bb 1000000000 --gas-budget 900000000 --json
```

Then you can test depositing reward:
```
# split gas coin with some amount
sui client pay-sui --input-coins <gas_coin> --recipients <sender> --amounts <amount_of_split> --gas-budget <gas_limit> --json
# deposit to contract
sui client call --package <package_address> --module reward --function deposit --args <reward_ledger_address> <coin_id> <amount> --gas-budget <gas_limit> --json

# example call
sui client pay-sui --input-coins 0xdea12abb5fecb42652e8b9e00e672e3e00d9d0171a717951f12661741b283128 --recipients 0x6f94e7051ad3a7c799fd913b22e06f076ce21932d618f3f0e661cf2cd56760bb --amounts 3000000000 --gas-budget 70000000 --json

sui client call --package 0x41010c2cc90d366dfdde90261208de39e8231e8401bcac781dd889b6ddbb3505 --module reward --function deposit --args 0xc329d96315b2298be8ada8c596b825c926ee7af46169c8e32bd3b837fa4eebad 0xfa8bf0e1da02b69f418bf11dfc9842262bdd99cc7b3ddc6e6abddb0a8db1188f 2000000000 --gas-budget 70000000 --json
```

Lastly you can test claiming:
```
sui client call --package <package_address> --module reward --function claim_reward --args <reward_ledger_address> <amount> --gas-budget <gas_limit> --json

# example
sui client call --package 0x41010c2cc90d366dfdde90261208de39e8231e8401bcac781dd889b6ddbb3505 --module reward --function claim_reward --args 0xc329d96315b2298be8ada8c596b825c926ee7af46169c8e32bd3b837fa4eebad 1000000000 --gas-budget 70000000 --json
```

## Testing

Simply run:
```
npm run test
```

For interaction with devnet you can also use `scripts` to run commands instead of sui client raw calls!
