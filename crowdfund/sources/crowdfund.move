
module crowdfund::crowdfund {
    use sui::tx_context::{TxContext, sender};
    use sui::object::{Self, UID, ID};
    use sui::transfer::{share_object, transfer, public_transfer};
    use sui::coin::{Self, Coin};
    use sui::clock::{Clock, timestamp_ms};

    const ErrorBadTiming: u64 = 0;
    const ErrorGoalReached: u64 = 1;
    const ErrorGoalNotReached: u64 = 2;
    const ErrorInvalidReceipt: u64 = 3;

    struct Crowdfund<phantom T> has key {
        id: UID,
        endDonate: u64,         // After this timestamp, no more donations are accepted
        goal: u64,              // Amount of Coins to be raised
        receiver: address,      // This address will receive the money
        donations: Coin<T>,
    }

    struct Receipt<phantom T> has key {
        id: UID,
        crowdfundId: ID,
        amount: u64,
    }

    public entry fun create_crowdfund<T>(goal: u64, receiver: address,
        endDonate: u64, ctx: &mut TxContext)
    {
        let crowdfund = Crowdfund<T> {
            id: object::new(ctx),
            endDonate: endDonate,
            goal: goal,
            receiver: receiver,
            donations: coin::zero<T>(ctx),
        };
        share_object(crowdfund);
    }

    public entry fun donate<T>(crowdfund: &mut Crowdfund<T>, money: Coin<T>,
        clock: &Clock, ctx: &mut TxContext)
    {
        assert!(timestamp_ms(clock) <= crowdfund.endDonate, ErrorBadTiming);

        let receipt = Receipt<T> {
            id: object::new(ctx),
            crowdfundId: object::id(crowdfund),
            amount: coin::value(&money),
        };
        coin::join(&mut crowdfund.donations, money);
        transfer(receipt, sender(ctx));
    }

    public entry fun withdraw<T>(crowdfund: &mut Crowdfund<T>, clock: &Clock,
        ctx: &mut TxContext)
    {
        assert!(timestamp_ms(clock) > crowdfund.endDonate, ErrorBadTiming);
        assert!(coin::value(&crowdfund.donations) >= crowdfund.goal, ErrorGoalNotReached);

        let total = coin::value(&crowdfund.donations);
        let money = coin::split(&mut crowdfund.donations, total, ctx);
        public_transfer(money, crowdfund.receiver);
    }

    public entry fun reclaim<T>(crowdfund: &mut Crowdfund<T>, receipt: Receipt<T>,
        clock: &Clock, ctx: &mut TxContext)
    {
        assert!(timestamp_ms(clock) > crowdfund.endDonate, ErrorBadTiming);
        assert!(coin::value(&crowdfund.donations) < crowdfund.goal, ErrorGoalReached);
        assert!(object::id(crowdfund) == receipt.crowdfundId, ErrorInvalidReceipt);

        let Receipt<T> {
            id,
            crowdfundId: _,
            amount,
        } = receipt;
        object::delete(id);
        let money = coin::split(&mut crowdfund.donations, amount, ctx);
        public_transfer(money, sender(ctx));
    }
}
