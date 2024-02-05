
module escrow::escrow {
    use sui::tx_context::{TxContext, sender};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use std::option::{Self, Option};

    const StateWaitDeposit: u64 = 0;
    const StateWaitRecipient: u64 = 1;
    const StateClosed: u64 = 2;

    const ErrorInsufficientAmount: u64 = 0;
    const ErrorInvalidState: u64 = 1;
    const ErrorUnauthorized: u64 = 2;

    struct Escrow<phantom T> has key {
        id: UID,
        state: u64,
        seller: address,
        buyer: address,
        amount: u64,
        payment: Option<Coin<T>>,
    }

    public entry fun create_contract<T>(amount: u64, buyer: address, ctx: &mut TxContext) {
        let contract = Escrow {
            id: object::new(ctx),
            state: StateWaitDeposit,
            seller: sender(ctx), // The creator is the seller
            buyer: buyer,
            amount: amount,
            payment: option::none<Coin<T>>(),
        };
        // The object is shared such that both buyer and seller can access it
        transfer::share_object(contract);
    }

    public entry fun deposit<T>(contract: &mut Escrow<T>, money: Coin<T>,
        ctx: &mut TxContext)
    {
        assert!(contract.state == StateWaitDeposit, ErrorInvalidState);
        assert!(sender(ctx) == contract.buyer, ErrorUnauthorized);
        assert!(coin::value<T>(&money) == contract.amount, ErrorInsufficientAmount);
        
        option::fill(&mut contract.payment, money);
        contract.state = StateWaitRecipient;
    }

    public entry fun pay<T>(contract: &mut Escrow<T>, ctx: &mut TxContext) {
        assert!(contract.state == StateWaitRecipient, ErrorInvalidState);
        assert!(sender(ctx) == contract.buyer, ErrorUnauthorized);

        let money = option::extract<Coin<T>>(&mut contract.payment);
        transfer::public_transfer(money, contract.seller);
        contract.state = StateClosed;
    }

    public entry fun refund<T>(contract: &mut Escrow<T>, ctx: &mut TxContext) {
        assert!(contract.state == StateWaitRecipient, ErrorInvalidState);
        assert!(sender(ctx) == contract.seller, ErrorUnauthorized);

        let money = option::extract<Coin<T>>(&mut contract.payment);
        transfer::public_transfer(money, contract.buyer);
        contract.state = StateClosed;
    }
}
