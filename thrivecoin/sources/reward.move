// Copyright (c) Thrive Protocol.
// SPDX-License-Identifier: MIT

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

  // errors
  const ENotWriter: u64 = 1;
  const ETreasuryInsufficient: u64 = 2;
  const EBalInsufficient: u64 = 3;
  const ERecipientDoesNotExist: u64 = 4;

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
    total_rewards: u64,
    balances: Table<address, u64>
  }

  // OTW
  struct REWARD has drop {}

  // initializer
  fun init(_otw: REWARD, ctx: &mut TxContext) {
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
      total_rewards: 0,
      balances: table::new<address, u64>(ctx)
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
    assert!(vec_set::contains(&writer_role.list, &account), ENotWriter);
    vec_set::remove(&mut writer_role.list, &account);
  }

  public fun writer_list(self: &WriterRole): VecSet<address> { self.list }

  // reward functions
  public fun deposit (
    reward_ledger: &mut RewardLedger,
    coin: &mut Coin<SUI>,
    amount: u64
  ) {
    let coin_balance = coin::balance_mut(coin);
    let payment = balance::split(coin_balance, amount);
    balance::join(&mut reward_ledger.treasury, payment);
  }

  public fun add_reward (
    writer_role: &WriterRole,
    reward_ledger: &mut RewardLedger,
    recipient: address,
    amount: u64,
    ctx: &mut TxContext
  ) {
    assert!(vec_set::contains(&writer_role.list, &tx_context::sender(ctx)), ENotWriter);
    if (!table::contains(&reward_ledger.balances, recipient)) {
      table::add(&mut reward_ledger.balances, recipient, 0);
    };

    let balance = table::borrow_mut(&mut reward_ledger.balances, recipient);
    *balance = *balance + amount;
    reward_ledger.total_rewards = reward_ledger.total_rewards + amount;
  }

  #[allow(lint(self_transfer))]
  public fun claim_reward (
    reward_ledger: &mut RewardLedger,
    amount: u64,
    ctx: &mut TxContext
  ) {
    let recipient = tx_context::sender(ctx);
    assert!(amount <= balance::value(&reward_ledger.treasury), ETreasuryInsufficient);

    assert!(table::contains(&reward_ledger.balances, recipient), ERecipientDoesNotExist);
    let balance = table::borrow_mut(&mut reward_ledger.balances, recipient);
    assert!(amount <= *balance, EBalInsufficient);

    *balance = *balance - amount;
    reward_ledger.total_rewards = reward_ledger.total_rewards - amount;
    if (*balance == 0) {
      table::remove(&mut reward_ledger.balances, recipient);
    };

    let withdrawal = coin::take(&mut reward_ledger.treasury, amount, ctx);
    transfer::public_transfer(withdrawal, recipient);
  }

  // Allows withdrawing funds that exceed total rewards
  public fun withdraw_treasury (
    _: &AdminRole,
    reward_ledger: &mut RewardLedger,
    recipient: address,
    amount: u64,
    ctx: &mut TxContext
  ) {
    let treasury = balance::value(&reward_ledger.treasury);
    assert!(treasury > reward_ledger.total_rewards, ETreasuryInsufficient);
    assert!(amount <= treasury - reward_ledger.total_rewards, ETreasuryInsufficient);

    let withdrawal = coin::take(&mut reward_ledger.treasury, amount, ctx);
    transfer::public_transfer(withdrawal, recipient);
  }

  public fun get_balance(self: &RewardLedger, recipient: address): u64 {
    if (!table::contains(&self.balances, recipient)) {
      return 0
    };

    return *table::borrow(&self.balances, recipient)
  }

  public fun has_balance(self: &RewardLedger, recipient: address): bool {
    return table::contains(&self.balances, recipient)
  }

  public fun treasury_balance(self: &RewardLedger): u64 {
    return balance::value(&self.treasury)
  }

  public fun total_rewards(self: &RewardLedger): u64 {
    return self.total_rewards
  }

  #[test_only]
  public fun test_init(ctx: &mut TxContext) {
    init(REWARD {}, ctx)
  }
}
