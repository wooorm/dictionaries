import fs from 'node:fs'
import path from 'node:path'
import assert from 'node:assert'
import test from 'tape'
import {readSync} from 'to-vfile'
import {isHidden} from 'is-hidden'
import isUtf8 from 'utf-8-validate'
import {bcp47Normalize} from 'bcp-47-normalize'

const root = 'dictionaries'

/**
 * @param {string} name
 * @returns {undefined}
 */
function bcp47(name) {
  assert.strictEqual(
    name,
    bcp47Normalize(name, {warning: warn}),
    name + ' should be a canonical, normal BCP-47 tag'
  )

  /**
   * @param {string} reason
   * @returns {undefined}
   */
  function warn(reason) {
    console.log('warning:%s: %s', name, reason)
  }
}

/**
 * @param {string} name
 * @returns {undefined}
 */
function utf8(name) {
  const dirname = path.join(root, name)
  const files = fs.readdirSync(dirname)
  let index = -1

  while (++index < files.length) {
    const d = files[index]
    if (isHidden(d)) continue
    const file = readSync(path.join(dirname, d))
    assert.ok(
      // @ts-expect-error: hopefully uint8array is fine for `is-utf-8`.
      typeof file.value === 'string' || isUtf8(file.value),
      file.basename + ' should be utf8'
    )
  }
}

/**
 * @param {string} name
 * @returns {undefined}
 */
function requiredFiles(name) {
  const dirname = path.join(root, name)
  const files = fs.readdirSync(dirname).filter((d) => !isHidden(d))
  const paths = [
    'index.dic',
    'index.aff',
    'readme.md',
    'index.js',
    'index.d.ts',
    'package.json'
  ]
  let index = -1

  while (++index < paths.length) {
    const d = paths[index]
    assert.notStrictEqual(files.indexOf(d), -1, 'should have `' + d + '`')
  }
}

test('dictionaries', (t) => {
  const files = fs.readdirSync(root)
  let index = -1

  while (++index < files.length) {
    const d = files[index]

    if (isHidden(d)) continue

    t.test(d, (st) => {
      st.doesNotThrow(() => {
        bcp47(d)
      }, 'Should have a canonical BCP-47 tag')

      st.doesNotThrow(() => {
        requiredFiles(d)
      }, 'All required files should exist')

      st.doesNotThrow(() => {
        utf8(d)
      }, 'All files should be in UTF-8')

      st.end()
    })
  }

  t.end()
})
