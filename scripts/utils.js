'use strict'

const { bech32 } = require('bech32')
const { SUI_DECIMALS } = require('@mysten/sui.js/utils')
const { web3Utils } = require('@thrivecoin/web3-utils')

/**
 * @param {string|Number} value
 * @returns {string}
 */
const fromUnit = (value) => {
  return web3Utils.fromERC20Unit(value, SUI_DECIMALS)
}

/**
 * @param {string|Number} value
 * @returns {string}
 */
const toUnit = (value) => {
  return web3Utils.toERC20Unit(value, SUI_DECIMALS)
}

/**
 * @param {string} input
 * @returns {Buffer}
 */
const bech32ToBuffer = (input) => {
  const decoded = bech32.decode(input)
  const bytes = bech32.fromWords(decoded.words)
  const hex = bytes.map(byte => byte.toString(16).padStart(2, '0'))
    .join('')
    .substring(2)
  return Buffer.from(hex, 'hex')
}

module.exports = {
  fromUnit,
  toUnit,
  bech32ToBuffer
}
