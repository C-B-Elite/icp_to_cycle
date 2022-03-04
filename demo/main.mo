import C "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import A "Account";
import U "Utils";

actor self{

    public type Memo = Nat64;

    public type Token = {
        e8s : Nat64;
    };

    public type TimeStamp = {
        timestamp_nanos: Nat64;
    };

    public type AccountIdentifier = Blob;

    public type SubAccount = Blob;

    public type BlockIndex = Nat64;

    public type TransferError = {
        #BadFee: {
            expected_fee: Token;
        };
        #InsufficientFunds: {
            balance: Token;
        };
        #TxTooOld: {
            allowed_window_nanos: Nat64;
        };
        #TxCreatedInFuture;
        #TxDuplicate : {
            duplicate_of: BlockIndex;
        };
    };

    public type TransferArgs = {
        memo: Memo;
        amount: Token;
        fee: Token;
        from_subaccount: ?SubAccount;
        to: AccountIdentifier;
        created_at_time: ?TimeStamp;
    };

    public type TransferResult = {
        #Ok: BlockIndex;
        #Err: TransferError;
    };

    public type Address = Blob;

    public type AccountBalanceArgs = {
        account : Address
    };

    public type BackResult = {
        #Ok : Blob;
        #Err : Text
    };

    type NotifyCanisterArgs = {
        // The of the block to send a notification about.
        block_height: BlockIndex;
        // Max fee, should be 10000 e8s.
        max_fee: Token;
        // Subaccount the payment came from.
        from_subaccount: ?SubAccount;
        // Canister that received the payment.
        to_canister: Principal;
        // Subaccount that received the payment.
        to_subaccount:  ?SubAccount;
    };

    public type LEDGER = actor{
        transfer : TransferArgs -> async TransferResult;
        account_balance : query AccountBalanceArgs -> async Token;
        notify_dfx : NotifyCanisterArgs -> async ();
    };

    type Status = {
        account_identifier : Blob;
        icp_balance : { e8s : Nat64 };
        cycle_ai : Blob;
        cycle_balance : Nat;
    };

    let CYCLE_MINTING_CANISTER = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
    let Ledger : LEDGER = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
    let TOP_UP_CANISTER_MEMO = 0x50555054 : Nat64;
    var owner : ?Principal = null;

    public shared({caller}) func set_owner(p : Principal) : async (){
        if(owner == null){
            owner := ?p
        }else{
            ignore do?{
                assert(caller == owner!);
                owner := ?p
            }
        }
    };

    public shared({caller}) func info() : async ?Status {
        do?{
            assert(caller == owner!);
            let default = Blob.fromArrayMut(Array.init<Nat8>(32, 0:Nat8));
            let self_subaccount = Blob.fromArray(U.principalToSubAccount(Principal.fromActor(self)));
            let self_cycle_ai = A.accountIdentifier(CYCLE_MINTING_CANISTER, self_subaccount);
            let self_ai = A.accountIdentifier(Principal.fromActor(self), default);
            {
                account_identifier = self_ai;
                icp_balance = await Ledger.account_balance({ account = self_ai });
                cycle_ai = self_cycle_ai;
                cycle_balance = C.balance();
            }
        }
    };

    public shared({caller}) func top_up() : async ?Text{
        do?{
            assert(caller == owner!);
            let default = Blob.fromArrayMut(Array.init<Nat8>(32, 0:Nat8));
            let self_subaccount = Blob.fromArray(U.principalToSubAccount(Principal.fromActor(self)));
            let self_cycle_ai = A.accountIdentifier(CYCLE_MINTING_CANISTER, self_subaccount);
            let self_ai = A.accountIdentifier(Principal.fromActor(self), default);
            switch(await Ledger.transfer({
                to = self_cycle_ai;
                fee = { e8s = 10_000 }; // 0.0001 icp
                memo = TOP_UP_CANISTER_MEMO;
                from_subaccount = ?default;
                amount = { e8s = 100_000 }; // 0.08
                created_at_time = null;
            })){
                case(#Ok(block_height)){
                    ignore await Ledger.notify_dfx(
                        {
                              to_canister = CYCLE_MINTING_CANISTER;
                              block_height = block_height;
                              from_subaccount = ?default;
                              to_subaccount = ?self_subaccount;
                              max_fee = { e8s = 10_000 };
                        }
                    );
                    "top up successfully"
                };
                case(#Err(e)){
                    debug_show(e)
                }
            }
        }
    };

    public query({caller}) func cycle_balance() : async ?Nat{
        do?{
            assert(caller == owner!);
            C.balance()
        }
    };

}