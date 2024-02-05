
module auction::auction {
    use sui::tx_context::{TxContext, sender};
    use sui::object::{Self, UID};
    use sui::transfer::{share_object, public_transfer};
    use sui::coin::{Self, Coin};
    use sui::clock::{Clock, timestamp_ms};
    use sui::dynamic_field;
    use std::string::{String};

    const StateWaitStart: u8 = 0;
    const StateWaitClosing: u8 = 1;
    const StateClosed: u8 = 2;

    const ErrorInvalidState: u64 = 0;
    const ErrorPermissionDenied: u64 = 1;
    const ErrorBadTiming: u64 = 2;
    const ErrorBidTooLow: u64 = 3;
    const ErrorHighestBidderCantWithdraw: u64 = 4;

    struct Auction<phantom T> has key {
        id: UID,
        state: u8,
        seller: address,
        thing: String,          // The thing being auctioned
        endTime: u64,           // After this timestamp, the auction is closed
        highestBidder: address,
        highestBid: u64,
    }

    public entry fun create_auction<T>(thing: String, minimumBid: u64,
        ctx: &mut TxContext)
    {
        let auction = Auction<T> {
            id: object::new(ctx),
            state: StateWaitStart,
            thing: thing,
            seller: sender(ctx),
            endTime: 0,
            highestBidder: @0x00,
            highestBid: minimumBid,
        };
        share_object(auction);
    }

    public entry fun start<T>(auction: &mut Auction<T>, duration: u64, clock: &Clock,
        ctx: &mut TxContext)
    {
        assert!(auction.state == StateWaitStart, ErrorInvalidState); // Auction already started
        assert!(sender(ctx) == auction.seller, ErrorPermissionDenied);

        auction.state = StateWaitClosing;
        auction.endTime = timestamp_ms(clock) + duration;
    }

    public entry fun bid<T>(auction: &mut Auction<T>, coin: Coin<T>, clock: &Clock,
        ctx: &mut TxContext)
    {
        assert!(auction.state == StateWaitClosing, ErrorInvalidState); // Auction not started
        assert!(timestamp_ms(clock) < auction.endTime, ErrorBadTiming);
        assert!(coin::value(&coin) > auction.highestBid, ErrorBidTooLow);

        let sender = sender(ctx);
        // if a participant makes a new bid, the previous one is automatically withdrawn
        if (auction.highestBidder == sender) {
            let oldMoney = dynamic_field::remove<address, Coin<T>>(&mut auction.id, sender);
            public_transfer(oldMoney, sender);
        };

        auction.highestBidder = sender;
        auction.highestBid = coin::value(&coin);
        dynamic_field::add(&mut auction.id, sender, coin);
    }

    public entry fun withdraw<T>(auction: &mut Auction<T>, ctx: &mut TxContext) {
        assert!(auction.state != StateWaitStart, ErrorInvalidState); // Auction not started

        let sender = sender(ctx);
        assert!(sender != auction.highestBidder, ErrorHighestBidderCantWithdraw);
        
        let money = dynamic_field::remove<address, Coin<T>>(&mut auction.id, sender);
        public_transfer(money, sender);
    }

    public entry fun end<T>(auction: &mut Auction<T>, clock: &Clock, ctx: &mut TxContext) {
        let sender = sender(ctx);
        assert!(sender == auction.seller, ErrorPermissionDenied);
        assert!(auction.state == StateWaitClosing, ErrorInvalidState); // Auction not started
        assert!(timestamp_ms(clock) >= auction.endTime, ErrorBadTiming); // Auction not ended

        auction.state = StateClosed;
        let money = dynamic_field::remove<address, Coin<T>>(&mut auction.id, auction.highestBidder);
        public_transfer(money, sender);
    }
}
