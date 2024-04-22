module thrivecoin::reward {
  // imports
  use sui::object::{Self, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::vec_set::{Self, VecSet};

  // errors
  const ENotWriter: u64 = 1;

  // structures
  struct AdminRole has key {
    id: UID
  }

  struct WriterRole has key {
    id: UID,
    list: VecSet<address>
  }

  // OTW
  struct REWARD has drop {}

  // initializer
  fun init(otw: REWARD, ctx: &mut TxContext) {
    transfer::transfer(AdminRole {
      id: object::new(ctx)
    }, tx_context::sender(ctx));

    transfer::share_object(WriterRole {
      id: object::new(ctx),
      list: vec_set::singleton(tx_context::sender(ctx))
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

  #[test_only]
  public fun test_init(ctx: &mut TxContext) {
    init(REWARD {}, ctx)
  }
}
