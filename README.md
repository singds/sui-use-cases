# Smart Contract Examples

- [ ] `anonymous_data`  
	I don't understand how this works.
- [x] `auction`
- [x] `bet_oracle`
- [x] `crowdfund`
- [ ] `decentralized_identity` difficult to understand.
- [x] `editableNFT`
- [x] `escrow`
- [x] `factory`
- [ ] `hello_world` missing description.
- [x] `htlc`  
    I don't understand the use case.  
    Maybe add a use case example in the example Readme.
- [ ] `payment_splitter` missing description
- [x] `simple_transfer`
- [x] `simple_wallet` can't be fully implemented in move, no dyn-dispatch.
- [x] `storage`
- [ ] `tinyamm` missing description
- [ ] `token_transfer`
- [ ] `upgradableProxy` can't be implemented in move, no dyn-dispatch
- [x] `vault`
- [x] `vesting`


### Why `simple_wallet` can't be fully implemented in Move:
In the `simple_wallet` Solidity implementation, the owner of the wallet can create
a `Transaction` with three fields: `to`, `amount` and `data`.

- `to`: the address of the contract to call.
- `amount`: the amount of native coins to send to `to` contract during the call.
- `data`: the data to send to `to` contract during the call.  
    `data` identifies the function of the contract to call and the arguments to pass to it.

The owner of the wallet can then execute the transaction that results in the execution of a function of the `to` contract.  
The contract that will be called by `simple_wallet` can be any contract, and is not known at compile time.  

This behavior can't be implemented in Move since all functions a piece of Move code can call must be known at compile time.  


### Why `upgradableProxy` can't be implemented in Move:
In `upgradableProxy` Solidity implementation, a **Caller** contract calls a **Proxy** contract that in turns calls a **Logic** contract.  
The **Logic** contract that is called by the **Proxy** contract can be changed.  
So the **Proxy** contract must be able to call any implementation of the **Logic** contract.  
As an example, the **Proxy** contract can call **Logic** contract implementation that have been deployed after the **Proxy** contract.

In Move we can make a **Proxy** module that can call a fixed set of **Logic** implementations, but all the **Logic** implementations must be known at compile time.  
