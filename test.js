import fs from 'fs'
import path from 'path'
import assert from 'assert'
import test from 'tape'
import {toVFile} from 'to-vfile'
import {isHidden} from 'is-hidden'
import isUtf8 from 'utf-8-validate'
import {bcp47Normalize} from 'bcp-47-normalize'

const own = {}.hasOwnProperty

const root = 'dictionaries'

const checks = {
  'Should have a canonical BCP-47 tag': bcp47,
  'All required files should exist': requiredFiles,
  'All files should be in UTF-8': utf8
}

function bcp47(name) {
  assert.strictEqual(
    name,
    bcp47Normalize(name, {warning: warn}),
    name + ' should be a canonical, normal BCP-47 tag'
  )

  function warn(reason) {
    console.log('warning:%s: %s', name, reason)
  }
}

function utf8(name) {
  const dirname = path.join(root, name)
  const files = fs.readdirSync(dirname)
  let index = -1

  while (++index < files.length) {
    const d = files[index]
    if (isHidden(d)) continue
    const file = toVFile.readSync(path.join(dirname, d))
    assert.ok(isUtf8(file.value), file.basename + ' should be utf8')
  }
}

function requiredFiles(name) {
  const dirname = path.join(root, name)
  const files = fs.readdirSync(dirname).filter((d) => !isHidden(d))
  const paths = [
    'index.dic',
    'index.aff',
    'readme.md',
    'index.js',
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
      let key

      for (key in checks) {
        if (!own.call(checks, key)) continue

        st.doesNotThrow(() => {
          checks[key](d)
        }, key)
      }

      st.end()
    })
  }

  t.end()
})
