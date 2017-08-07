'use strict';

/* eslint-disable import/no-dynamic-require */

module.exports = listOfDictionaries;

var fs = require('fs');
var path = require('path');
var u = require('unist-builder');
var zone = require('mdast-zone');
var hidden = require('is-hidden');
var negate = require('negate');

var join = path.join;

var root = join(process.cwd(), 'dictionaries');

function listOfDictionaries() {
  return transformer;
}

function transformer(tree) {
  zone(tree, 'support', replace);
}

function replace(start, nodes, end) {
  var rows = fs
    .readdirSync(root)
    .filter(negate(hidden))
    .map(row);

  return [
    start,
    u('paragraph', [
      u('text', 'In total, ' + rows.length + ' dictionaries are provided.')
    ]),
    u('table', [
      u('tableRow', [
        u('tableCell', [u('text', 'Name')]),
        u('tableCell', [u('text', 'Description')]),
        u('tableCell', [u('text', 'License')])
      ])
    ].concat(rows)),
    end
  ];
}

function row(name) {
  var url = 'dictionaries/' + name;
  var base = join(root, name);
  var pack = JSON.parse(fs.readFileSync(join(base, 'package.json')));
  var license = [u('text', pack.license)];
  var description = pack.description.replace(/\sspelling.+$/, '');

  if (fs.existsSync(join(base, 'LICENSE'))) {
    license = [u('link', {url: url + '/LICENSE'}, license)];
  }

  return u('tableRow', [
    u('tableCell', [u('link', {url: url}, [u('inlineCode', pack.name)])]),
    u('tableCell', [u('text', description)]),
    u('tableCell', license)
  ]);
}
