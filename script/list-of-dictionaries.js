/**
 * @typedef {import('mdast').PhrasingContent} PhrasingContent
 * @typedef {import('mdast').Root} Root
 * @typedef {import('mdast').TableRow} TableRow
 *
 * @typedef {import('type-fest').PackageJson} PackageJson
 */

import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import {zone} from 'mdast-zone'

const root = new URL('../dictionaries/', import.meta.url)

/**
 * @returns
 *   Transform.
 */
export default function remarkListDictionaries() {
  /**
   * @param {Root} tree
   *   Tree.
   * @returns {Promise<undefined>}
   *   Nothing.
   */
  return async function (tree) {
    const files = await fs.readdir(root)
    const rows = await Promise.all(
      files
        .filter(function (d) {
          return d.charAt(0) !== '.'
        })
        .map(function (d) {
          return row(d)
        })
    )

    zone(tree, 'support', function (start, nodes, end) {
      return [
        start,
        {
          type: 'paragraph',
          children: [
            {
              type: 'text',
              value: 'In total ' + rows.length + ' dictionaries are provided.'
            }
          ]
        },
        {
          type: 'table',
          children: [
            {
              type: 'tableRow',
              children: [
                {type: 'tableCell', children: [{type: 'text', value: 'Name'}]},
                {
                  type: 'tableCell',
                  children: [{type: 'text', value: 'Description'}]
                },
                {
                  type: 'tableCell',
                  children: [{type: 'text', value: 'License'}]
                }
              ]
            },
            ...rows
          ]
        },
        end
      ]
    })
  }
}

/**
 * @param {string} name
 *   Name.
 * @returns {Promise<TableRow>}
 *   Row.
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
      {
        type: 'link',
        url: 'dictionaries/' + name + '/license',
        children: [{type: 'text', value: pack.license}]
      }
    ]
  } else {
    license = [{type: 'text', value: pack.license}]
  }

  return {
    type: 'tableRow',
    children: [
      {
        type: 'tableCell',
        children: [
          {
            type: 'link',
            url: 'dictionaries/' + name,
            children: [{type: 'inlineCode', value: pack.name}]
          }
        ]
      },
      {type: 'tableCell', children: [{type: 'text', value: description}]},
      {type: 'tableCell', children: license}
    ]
  }
}
