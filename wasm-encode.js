#!/usr/bin/env node

/**
 * Cleaned version of:
 * <https://merckx.dev/notes/embedding-binary-data-in-wasm.html>.
 *
 * To do: when Node supports WASM imports, we can drop `fs` and start using
 * this.
 *
 * In the future, when importing WASM is supported in Node, we can use this.
 * This little script takes an input file path and an output file path as
 * arguments and generates a WASM file from the former to the latter.
 * The data from the WASM can then be accessed with:
 *
 * ```js
 * import {data} from './output.wasm'
 * const u8 = data.buffer
 * ```
 */

import {Buffer} from 'node:buffer'
import fs from 'node:fs/promises'
import process from 'node:process'
// @ts-expect-error: untyped.
import {unsigned, signed} from 'leb128'

const data = await fs.readFile(process.argv[2])

/** @type {Buffer} */
const size = unsigned.encode(data.length)
/** @type {Buffer} */
const length = signed.encode(data.length)
/** @type {Buffer} */
const globalL = unsigned.encode(5 + length.length)
/** @type {Buffer} */
const dataL = unsigned.encode(5 + size.length + data.length)
/** @type {Buffer} */
const memoryPages = unsigned.encode(Math.ceil(data.length / 65_536))
/** @type {Buffer} */
const memoryL = unsigned.encode(2 + memoryPages.length)

await fs.writeFile(
  process.argv[3],
  bin`
  00 61 73 6d                                         // WASM_BINARY_MAGIC
  01 00 00 00                                         // WASM_BINARY_VERSION
  05 ${memoryL} 01                                    // section "Memory" (5)
  00 ${memoryPages}                                   // memory 0
  06 ${globalL} 01 7f 00 41 ${length} 0b              // section "Global" (6)
  07 11 02 04 6461 7461 02 00 06 6c65 6e67 7468 03 00 // section "Export" (7)
  0b ${dataL} 01                                      // section "Data" (11)
  00 41 00 0b ${size}                                 // data segment header 0
  ${data}                                             // data
  `
)

/**
 *
 * @param {TemplateStringsArray} values
 * @param  {...Buffer} inserts
 * @returns {Buffer}
 */
function bin(values, ...inserts) {
  /** @type {Array<Buffer>} */
  const result = []
  let index = -1

  while (++index < values.length) {
    const bytes = values[index].replace(/\/\/(.*?)\n/g, '').replace(/\s+/g, '')
    result.push(Buffer.from(bytes, 'hex'))

    if (index < inserts.length) {
      result.push(inserts[index])
    }
  }

  return Buffer.concat(result)
}
