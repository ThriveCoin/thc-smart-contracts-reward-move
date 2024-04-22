#[test_only]
module thrivecoin::reward_test {
  use thrivecoin::reward::{
    ENotWriter,
    EBalInsufficient,
    AdminRole,
    WriterRole,
    RewardLedger,
    transfer_admin_role,
    add_writer,
    del_writer,
    writer_list,
    add_reward,
    claim_reward,
    get_balance,
    has_balance,
    test_init
  };
  use sui::test_scenario as ts;
  use sui::vec_set::{Self};
  use std::vector;

  const ADMIN: address = @0xAD;

  #[test]
  fun test_module_init () {
    let ts = ts::begin(@0x0);
    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    // ensure that admin role belongs to ADMIN
    {
      ts::next_tx(&mut ts, ADMIN);
      let ids = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids) == 1, 1);

      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::size(&writer_list(&writer)) == 1, 1);
      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_transfer_admin_role () {
    let ts = ts::begin(@0x0);
    let new_owner: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    // ensure that admin role belongs to ADMIN
    {
      ts::next_tx(&mut ts, ADMIN);
      let role: AdminRole = ts::take_from_sender(&ts);
      transfer_admin_role(role, new_owner);
    };

    {
      ts::next_tx(&mut ts, ADMIN);

      let ids_admin = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids_admin) == 0, 1);

      let ids_new_owner = ts::ids_for_address<AdminRole>(new_owner);
      assert!(vector::length(&ids_new_owner) == 1, 1);
    };

    ts::end(ts);
  }

  #[test]
  fun test_add_writer () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc), 1);

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_del_writer () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc), 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      del_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc) == false, 1);

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = ENotWriter)]
  fun test_add_reward_fail () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;
    let non_writer = @0xAD3;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let ids = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids) == 1, 1);

      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::size(&writer_list(&writer)) == 1, 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, non_writer);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      add_reward(&writer, &mut reward_ledger, recipient, 13, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_add_reward_new () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(has_balance(&reward_ledger, recipient) == false, 1);
      add_reward(&writer, &mut reward_ledger, recipient, 13, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 13, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_increase_reward () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(has_balance(&reward_ledger, recipient) == false, 1);
      add_reward(&writer, &mut reward_ledger, recipient, 13, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 13, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      add_reward(&writer, &mut reward_ledger, recipient, 5, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 18, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_get_balance_empty () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 0, 1);
      assert!(has_balance(&reward_ledger, recipient) == false, 1);

      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_get_balance_existing () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      add_reward(&writer, &mut reward_ledger, recipient, 11, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 11, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = EBalInsufficient)]
  fun test_claim_reward_fail_empty () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, recipient);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(has_balance(&reward_ledger, recipient) == false, 1);
      claim_reward(&mut reward_ledger, 11, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = EBalInsufficient)]
  fun test_claim_reward_insufficient () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      add_reward(&writer, &mut reward_ledger, recipient, 5, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 5, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, recipient);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      claim_reward(&mut reward_ledger, 11, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_claim_reward_decrease () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      add_reward(&writer, &mut reward_ledger, recipient, 13, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 13, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, recipient);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      claim_reward(&mut reward_ledger, 11, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 2, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_claim_reward_remove () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      add_reward(&writer, &mut reward_ledger, recipient, 13, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 13, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, recipient);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      claim_reward(&mut reward_ledger, 13, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 0, 1);
      assert!(has_balance(&reward_ledger, recipient) == false, 1);

      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }
}
