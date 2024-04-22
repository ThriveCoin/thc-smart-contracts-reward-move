module thrivecoin::reward {
  // imports
  use sui::object::{Self, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::vec_set::{Self, VecSet};
  use sui::table::{Self, Table};
  use sui::sui::SUI;
  use sui::coin::{Self, Coin};
  use sui::balance::{Self, Balance};
  use sui::types;

  // errors
  const ENotOneTimeWitness: u64 = 1;
  const ENotWriter: u64 = 2;
  const ETreasuryInsufficient: u64 = 3;
  const EBalInsufficient: u64 = 4;

  // structures
  struct AdminRole has key {
    id: UID
  }

  struct WriterRole has key {
    id: UID,
    list: VecSet<address>
  }
  
  struct RewardLedger has key, store {
    id: UID,
    treasury: Balance<SUI>,
    balance: Table<address, u64>
  }

  // OTW
  struct REWARD has drop {}

  // initializer
  fun init(otw: REWARD, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness(&otw), ENotOneTimeWitness);

    transfer::transfer(AdminRole {
      id: object::new(ctx)
    }, tx_context::sender(ctx));

    transfer::share_object(WriterRole {
      id: object::new(ctx),
      list: vec_set::singleton(tx_context::sender(ctx))
    });

    transfer::share_object(RewardLedger {
      id: object::new(ctx),
      treasury: balance::zero(),
      balance: table::new<address, u64>(ctx)
    });
  }

  // role functions
  public fun transfer_admin_role (admin_role: AdminRole, new_owner: address) {
    transfer::transfer(admin_role, new_owner);
  }

  public fun add_writer (_: &AdminRole, writer_role: &mut WriterRole, account: address) {
    vec_set::insert(&mut writer_role.list, account);
  }

  public fun del_writer(_: &AdminRole, writer_role: &mut WriterRole, account: address) {
    vec_set::remove(&mut writer_role.list, &account);
  }

  public fun writer_list(self: &WriterRole): VecSet<address> { self.list }

  // reward functions
  public fun deposit (
    reward_ledger: &mut RewardLedger,
    payment: &mut Coin<SUI>
  ) {
    let coin_balance = coin::balance_mut(payment);
    let paid = balance::withdraw_all(coin_balance);
    balance::join(&mut reward_ledger.treasury, paid);
  }

  public fun add_reward (
    writer_role: &WriterRole,
    reward_ledger: &mut RewardLedger,
    recipient: address,
    amount: u64,
    ctx: &mut TxContext
  ) {
    assert!(vec_set::contains(&writer_role.list, &tx_context::sender(ctx)), ENotWriter);
    if (!table::contains(&reward_ledger.balance, recipient)) {
      table::add(&mut reward_ledger.balance, recipient, 0);
    };

    let balance = table::borrow_mut(&mut reward_ledger.balance, recipient);
    *balance = *balance + amount;
  }

  #[allow(lint(self_transfer))]
  public fun claim_reward (
    reward_ledger: &mut RewardLedger,
    amount: u64,
    ctx: &mut TxContext
  ) {
    let recipient = tx_context::sender(ctx);
    assert!(amount <= balance::value(&reward_ledger.treasury), ETreasuryInsufficient);

    assert!(table::contains(&reward_ledger.balance, recipient), EBalInsufficient);
    let balance = table::borrow_mut(&mut reward_ledger.balance, recipient);
    assert!(amount <= *balance, EBalInsufficient);

    *balance = *balance - amount;
    if (*balance == 0) {
      table::remove(&mut reward_ledger.balance, recipient);
    };

    let withdrawal = coin::take(&mut reward_ledger.treasury, amount, ctx);
    transfer::public_transfer(withdrawal, recipient);
  }

  public fun get_balance(self: &RewardLedger, recipient: address): u64 {
    if (!table::contains(&self.balance, recipient)) {
      return 0
    };

    return *table::borrow(&self.balance, recipient)
  }

  public fun has_balance(self: &RewardLedger, recipient: address): bool {
    return table::contains(&self.balance, recipient)
  }

  public fun treasury_balance(self: &RewardLedger): u64 {
    return balance::value(&self.treasury)
  }

  #[test_only]
  public fun test_init(ctx: &mut TxContext) {
    init(REWARD {}, ctx)
  }
}
