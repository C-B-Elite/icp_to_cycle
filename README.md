测试ICP -> Cycle
ICP转账
Transfer ICP:

Ledger canister
	System subnet: ryjl3-tyaaa-aaaaa-aaaba-cai
		transfer
		balance
		notify dfx
Ledger :
	blob(AccountIdentifier) - balance { e8s : Nat64 }

AccountIdentifier : blob : [u8(Nat8); 32]
	Principal : Principal -> Blob : [u8(Nat8); 32]
	Subaccount : Blob : [u8(Nat8); 32]
	AccountIdentifier : Blob[u8(Nat8); 32] =  CRC32(SHA224(principal + sub_account))
		eg : ai = crc32(sha224(caller + [0x01; 0x00; ···; 0x00])) : 2^256 + 1 个

Users can only operate their main account and sub account.
``` await ledger.transfer(xxx) ```
To : to : AccountIdentifier


Top up:
Cycle mint canister : rkp4c-7iaaa-aaaaa-aaaca-cai
CycleSubAccount
	[principal_size, principal_blob, 0x00:Nat8]
	caller -> sub account
Cycle AccountIdentifier
	AI = CRC32(SHA224(cmc_principal, subaccount))
Transfer


Memo : top up canister memo : let TOP_UP_CANISTER_MEMO = 0x50555054 : Nat64
To : cycle account identifier
Return : #Ok(block_hight)

Notify
Await ledger.notify_dfx(args)
Args : {
	to_canister : Principal(CMC);
	block_hight : return value of tranfer
	from_subaccount : icp from where : ?Principal;
	to_subaccount : should_top_up_canister_subaccount[generate cycle account identifier] : ?Blob;
	max_fee = { e8s = 10_000}
}
