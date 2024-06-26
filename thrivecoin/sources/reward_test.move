#[test_only]
module thrivecoin::reward_test {
  use thrivecoin::reward::{
    ENotWriter,
    ETreasuryInsufficient,
    EBalInsufficient,
    ERecipientDoesNotExist,
    AdminRole,
    WriterRole,
    RewardLedger,
    transfer_admin_role,
    add_writer,
    del_writer,
    writer_list,
    deposit,
    add_reward,
    claim_reward,
    withdraw_treasury,
    get_balance,
    has_balance,
    treasury_balance,
    total_rewards,
    test_init
  };
  use sui::transfer;
  use sui::test_scenario as ts;
  use sui::sui::SUI;
  use sui::coin::{Self, Coin};
  use sui::balance::{ENotEnough};
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
  #[expected_failure(abort_code = ENotWriter)]
  fun test_del_writer_not_exists () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer_list(&writer), &admin_ref), 1);
      assert!(vec_set::contains(&writer_list(&writer), &writer_acc) == false, 1);

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
  fun test_deposit () {
    let ts = ts::begin(@0x0);
    let rnd_addr: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(100, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      assert!(treasury_balance(&reward_ledger) == 0, 1);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 100);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(treasury_balance(&reward_ledger) == 100, 1);
      assert!(coin::value(&coin) == 0, 1);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, rnd_addr);
      let coin = coin::mint_for_testing<SUI>(5, ts::ctx(&mut ts));
      transfer::public_transfer(coin, rnd_addr);
    };

    {
      ts::next_tx(&mut ts, rnd_addr);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 3);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, rnd_addr);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(treasury_balance(&reward_ledger) == 103, 1);
      assert!(coin::value(&coin) == 2, 1);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = ENotEnough)]
  fun test_deposit_amount_insufficient () {
    let ts = ts::begin(@0x0);

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(100, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      assert!(treasury_balance(&reward_ledger) == 0, 1);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 101);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(total_rewards(&reward_ledger) == 13, 1);

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
      assert!(total_rewards(&reward_ledger) == 13, 1);

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
      assert!(total_rewards(&reward_ledger) == 18, 1);

      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_multiple_balances () {
    let ts = ts::begin(@0x0);
    let recipient1: address = @0xAD2;
    let recipient2: address = @0xAD3;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(has_balance(&reward_ledger, recipient1) == false, 1);
      add_reward(&writer, &mut reward_ledger, recipient1, 13, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient1) == 13, 1);
      assert!(has_balance(&reward_ledger, recipient1) == true, 1);
      assert!(total_rewards(&reward_ledger) == 13, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      add_reward(&writer, &mut reward_ledger, recipient2, 5, ts::ctx(&mut ts));

      ts::return_shared(writer);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient1) == 13, 1);
      assert!(has_balance(&reward_ledger, recipient1) == true, 1);
      assert!(get_balance(&reward_ledger, recipient2) == 5, 1);
      assert!(has_balance(&reward_ledger, recipient2) == true, 1);
      assert!(total_rewards(&reward_ledger) == 18, 1);

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
  #[expected_failure(abort_code = ETreasuryInsufficient)]
  fun test_claim_reward_treasury_insufficient () {
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
  #[expected_failure(abort_code = ERecipientDoesNotExist)]
  fun test_claim_reward_fail_bal_empty () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(100, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 100);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
  fun test_claim_reward_fail_bal_insufficient () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(100, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 100);

      ts::return_to_sender(&ts, coin);
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
      let coin = coin::mint_for_testing<SUI>(100, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 100);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(treasury_balance(&reward_ledger) == 100, 1);
      assert!(total_rewards(&reward_ledger) == 13, 1);

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
      ts::next_tx(&mut ts, recipient);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 2, 1);
      assert!(has_balance(&reward_ledger, recipient) == true, 1);
      assert!(treasury_balance(&reward_ledger) == 89, 1);
      assert!(total_rewards(&reward_ledger) == 2, 1);
      assert!(coin::value(&coin) == 11, 1);

      ts::return_to_sender(&ts, coin);
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
      let coin = coin::mint_for_testing<SUI>(100, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 100);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(treasury_balance(&reward_ledger) == 100, 1);
      assert!(total_rewards(&reward_ledger) == 13, 1);

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
      ts::next_tx(&mut ts, recipient);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 0, 1);
      assert!(has_balance(&reward_ledger, recipient) == false, 1);
      assert!(treasury_balance(&reward_ledger) == 87, 1);
      assert!(total_rewards(&reward_ledger) == 0, 1);
      assert!(coin::value(&coin) == 13, 1);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = ETreasuryInsufficient)]
  fun test_withdraw_treasury_lt_total_rewards () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;
    let wd_recipient: address = @0xAD3;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(5, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 5);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(treasury_balance(&reward_ledger) == 5, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      withdraw_treasury(&admin, &mut reward_ledger, wd_recipient, 1, ts::ctx(&mut ts));

      ts::return_to_sender(&ts, admin);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = ETreasuryInsufficient)]
  fun test_withdraw_treasury_eq_total_rewards () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;
    let wd_recipient: address = @0xAD3;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(13, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 13);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(treasury_balance(&reward_ledger) == 13, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      withdraw_treasury(&admin, &mut reward_ledger, wd_recipient, 1, ts::ctx(&mut ts));

      ts::return_to_sender(&ts, admin);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = ETreasuryInsufficient)]
  fun test_withdraw_treasury_amount_exceeds () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;
    let wd_recipient: address = @0xAD3;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(14, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 14);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(treasury_balance(&reward_ledger) == 14, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      withdraw_treasury(&admin, &mut reward_ledger, wd_recipient, 2, ts::ctx(&mut ts));

      ts::return_to_sender(&ts, admin);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_withdraw_treasury_amount_lt () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;
    let wd_recipient: address = @0xAD3;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(20, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 20);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(treasury_balance(&reward_ledger) == 20, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      withdraw_treasury(&admin, &mut reward_ledger, wd_recipient, 5, ts::ctx(&mut ts));

      ts::return_to_sender(&ts, admin);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, wd_recipient);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 13, 1);
      assert!(treasury_balance(&reward_ledger) == 15, 1);
      assert!(total_rewards(&reward_ledger) == 13, 1);
      assert!(coin::value(&coin) == 5, 1);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }

  #[test]
  fun test_withdraw_treasury_amount_eq () {
    let ts = ts::begin(@0x0);
    let recipient: address = @0xAD2;
    let wd_recipient: address = @0xAD3;

    {
      ts::next_tx(&mut ts, ADMIN);
      test_init(ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let coin = coin::mint_for_testing<SUI>(20, ts::ctx(&mut ts));
      transfer::public_transfer(coin, ADMIN);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);

      deposit(&mut reward_ledger, &mut coin, 20);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
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
      assert!(treasury_balance(&reward_ledger) == 20, 1);

      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      withdraw_treasury(&admin, &mut reward_ledger, wd_recipient, 7, ts::ctx(&mut ts));

      ts::return_to_sender(&ts, admin);
      ts::return_shared(reward_ledger);
    };

    {
      ts::next_tx(&mut ts, wd_recipient);
      let coin: Coin<SUI> = ts::take_from_sender(&ts);
      let reward_ledger: RewardLedger = ts::take_shared(&ts);

      assert!(get_balance(&reward_ledger, recipient) == 13, 1);
      assert!(treasury_balance(&reward_ledger) == 13, 1);
      assert!(total_rewards(&reward_ledger) == 13, 1);
      assert!(coin::value(&coin) == 7, 1);

      ts::return_to_sender(&ts, coin);
      ts::return_shared(reward_ledger);
    };

    ts::end(ts);
  }
}
