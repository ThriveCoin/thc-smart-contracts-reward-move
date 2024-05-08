'use strict'

const { SUI_NETWORKS } = require('./constants')
const yargs = require('yargs')
  .option('network', { alias: 'n', type: 'string', demandOption: true, default: 'devnet', choices: SUI_NETWORKS })
  .option('priv-key', { alias: 'k', type: 'string', demandOption: true })
  .option('pkg', { alias: 'p', type: 'string', demandOption: true })
  .option('reward-ledger', { alias: 'l', type: 'string', demandOption: true })
  .option('amount', { alias: 'a', type: 'number', demandOption: true })
const { getFullnodeUrl, SuiClient } = require('@mysten/sui.js/client')
const { Ed25519Keypair, Ed25519PublicKey } = require('@mysten/sui.js/keypairs/ed25519')
const { TransactionBlock } = require('@mysten/sui.js/transactions')

const { bech32ToBuffer, fromUnit, toUnit } = require('./utils')
const { inspect } = require('util')

const main = async () => {
  let {
    privKey, network, pkg, rewardLedger, amount
  } = yargs.argv
  const suiClient = new SuiClient({ url: getFullnodeUrl(network) })
  amount = toUnit(amount)

  const keypair = Ed25519Keypair.fromSecretKey(bech32ToBuffer(privKey))

  const publicKey = new Ed25519PublicKey(keypair.getPublicKey().toRawBytes())
  const address = publicKey.toSuiAddress()
  console.log('opened address', address)

  const bal = await suiClient.getBalance({ owner: address })
  console.log('balance (unit)', bal.totalBalance)
  console.log('balance', fromUnit(bal.totalBalance))
  console.debug('package', pkg)
  console.debug('claim reward', { rewardLedger, amount })

  const txb = new TransactionBlock()
  txb.moveCall({
    target: `${pkg}::reward::claim_reward`,
    arguments: [
      txb.object(rewardLedger),
      txb.pure.u64(amount)
    ]
  })
  txb.setGasBudget(parseInt(+bal.totalBalance * 0.01))

  const res = await suiClient.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    signer: keypair,
    options: {
      showEffects: true,
      showObjectChanges: true
    }
  })

  console.log('tx digest', res.digest)
  if (res.effects.status.error || res.effects.status.status !== 'success') {
    console.log(inspect(res, false, 100, true))
    throw new Error(res.effects.status.error)
  }

  await suiClient.waitForTransactionBlock({
    digest: res.digest
  })

  const balanceObj = res.objectChanges.find(x =>
    x.objectType.endsWith('ynamic_field::Field<address, u64>')
  )
  const balance = await suiClient.getObject({ id: balanceObj.objectId, options: { showContent: true } })
  console.log('balance', fromUnit(balance.data?.content?.fields?.value))

  const ledger = await suiClient.getObject({ id: rewardLedger, options: { showContent: true } })
  console.log('total rewards', fromUnit(ledger.data?.content?.fields?.total_rewards))
  console.log('treasury', fromUnit(ledger.data?.content?.fields?.treasury))
}

main().catch(console.error)
