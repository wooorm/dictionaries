import process from 'node:process'
import fs from 'node:fs'
import path from 'node:path'
import {u} from 'unist-builder'
import {zone} from 'mdast-zone'
import {isHidden} from 'is-hidden'

const join = path.join

const root = join(process.cwd(), 'dictionaries')

export default function listOfDictionaries() {
  return transformer
}

function transformer(tree) {
  zone(tree, 'support', replace)
}

function replace(start, nodes, end) {
  const rows = fs
    .readdirSync(root)
    .filter((d) => !isHidden(d))
    .map((d) => row(d))

  return [
    start,
    u('paragraph', [
      u('text', 'In total ' + rows.length + ' dictionaries are provided.')
    ]),
    u(
      'table',
      [
        u('tableRow', [
          u('tableCell', [u('text', 'Name')]),
          u('tableCell', [u('text', 'Description')]),
          u('tableCell', [u('text', 'License')])
        ])
      ].concat(rows)
    ),
    end
  ]
}

function row(name) {
  const url = 'dictionaries/' + name
  const base = join(root, name)
  const pack = JSON.parse(fs.readFileSync(join(base, 'package.json')))
  let license = [u('text', pack.license)]
  const description = pack.description.replace(/\sspelling.+$/, '')

  if (fs.existsSync(join(base, 'license'))) {
    license = [u('link', {url: url + '/license'}, license)]
  }

  return u('tableRow', [
    u('tableCell', [u('link', {url}, [u('inlineCode', pack.name)])]),
    u('tableCell', [u('text', description)]),
    u('tableCell', license)
  ])
}
