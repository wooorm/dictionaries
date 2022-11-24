/**
 * @typedef {import('mdast').Root} Root
 * @typedef {import('mdast').TableRow} TableRow
 * @typedef {import('mdast').PhrasingContent} PhrasingContent
 * @typedef {import('type-fest').PackageJson} PackageJson
 */

import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import {u} from 'unist-builder'
import {zone} from 'mdast-zone'
import {isHidden} from 'is-hidden'

const root = new URL('../dictionaries/', import.meta.url)

/** @type {import('unified').Plugin<[], Root>} */
export default function listOfDictionaries() {
  return async function (tree) {
    const files = await fs.readdir(root)
    const rows = await Promise.all(
      files.filter((d) => !isHidden(d)).map((d) => row(d))
    )

    zone(tree, 'support', function (start, nodes, end) {
      return [
        start,
        u('paragraph', [
          u('text', 'In total ' + rows.length + ' dictionaries are provided.')
        ]),
        u('table', [
          u('tableRow', [
            u('tableCell', [u('text', 'Name')]),
            u('tableCell', [u('text', 'Description')]),
            u('tableCell', [u('text', 'License')])
          ]),
          ...rows
        ]),
        end
      ]
    })
  }
}

/**
 *
 * @param {string} name
 * @returns {Promise<TableRow>}
 */

async function row(name) {
  const base = new URL(name + '/', root)
  /** @type {PackageJson} */
  const pack = JSON.parse(
    String(await fs.readFile(new URL('package.json', base)))
  )
  assert(pack.name, 'expected `name` in `package.json`')
  assert(pack.description, 'expected `description` in `package.json`')
  assert(
    typeof pack.license === 'string',
    'expected `license` (`string`) in `package.json`'
  )

  const description = pack.description.replace(/\sspelling.+$/, '')

  let exists = false

  try {
    await fs.access(new URL('license', base), fs.constants.F_OK)
    exists = true
  } catch {}

  /** @type {Array<PhrasingContent>} */
  let license

  if (exists) {
    license = [
      u('link', {url: 'dictionaries/' + name + '/license'}, [
        u('text', pack.license)
      ])
    ]
  } else {
    license = [u('text', pack.license)]
  }

  return u('tableRow', [
    u('tableCell', [
      u('link', {url: 'dictionaries/' + name}, [u('inlineCode', pack.name)])
    ]),
    u('tableCell', [u('text', description)]),
    u('tableCell', license)
  ])
}
