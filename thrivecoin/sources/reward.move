module thrivecoin::reward {
  // imports
  use sui::object::{Self, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::vec_set::{Self, VecSet};
  use sui::table::{Self, Table};
  use sui::types;

  // errors
  const ENotOneTimeWitness: u64 = 1;
  const ENotWriter: u64 = 2;
  const EBalInsufficient: u64 = 3;

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

  public fun claim_reward (
    reward_ledger: &mut RewardLedger,
    amount: u64,
    ctx: &mut TxContext
  ) {
    let recipient = tx_context::sender(ctx);
    assert!(table::contains(&reward_ledger.balance, recipient), EBalInsufficient);
    let balance = table::borrow_mut(&mut reward_ledger.balance, recipient);
    assert!(amount <= *balance, EBalInsufficient);
    *balance = *balance - amount;
    if (*balance == 0) {
      table::remove(&mut reward_ledger.balance, recipient);
    };
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

  #[test_only]
  public fun test_init(ctx: &mut TxContext) {
    init(REWARD {}, ctx)
  }
}
