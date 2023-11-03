import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import test from 'node:test'
import {bcp47Normalize} from 'bcp-47-normalize'
import isUtf8 from 'utf-8-validate'

test('dictionaries', async function (t) {
  const base = new URL('dictionaries/', import.meta.url)
  const folders = await fs.readdir(base)
  let index = -1

  while (++index < folders.length) {
    const folder = folders[index]

    if (folder.charAt(0) === '.') continue

    // eslint-disable-next-line no-await-in-loop
    await t.test(folder, async function (t) {
      const folderUrl = new URL(folder + '/', base)

      await t.test('should be a canonical, normal BCP-47 tag', function () {
        assert.strictEqual(
          folder,
          bcp47Normalize(folder, {
            warning(reason) {
              console.log('warning:%s: %s', folder, reason)
            }
          })
        )
      })

      await t.test('should contain all required files', async function () {
        const basenames = [
          'index.dic',
          'index.aff',
          'readme.md',
          'index.js',
          'index.d.ts',
          'package.json'
        ]

        await Promise.all(
          basenames.map(async function (d) {
            return fs.access(new URL(d, folderUrl), fs.constants.F_OK)
          })
        )
      })

      await t.test('should contain UTF-8', async function () {
        const files = await fs.readdir(folderUrl)

        await Promise.all(
          files.map(async function (d) {
            const buf = await fs.readFile(new URL(d, folderUrl))
            assert(isUtf8(buf))
          })
        )
      })
    })
  }
})
