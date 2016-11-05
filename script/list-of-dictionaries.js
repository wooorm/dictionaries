'use strict';

/* eslint-disable import/no-dynamic-require */

/* Expose. */
module.exports = listOfDictionaries;

/* Dependencies. */
var fs = require('fs');
var path = require('path');
var u = require('unist-builder');
var visit = require('unist-util-visit');
var hidden = require('is-hidden');
var negate = require('negate');

/* Methods. */
var dir = fs.readdirSync;
var exists = fs.existsSync;
var join = path.join;

/* Values. */
var cwd = process.cwd();

/* Add a list of dictionaries. */
function listOfDictionaries() {
  return transformer;
}

/* Replace the first `table` node in `readme.md`. */
function transformer(tree, file) {
  if (file.stem === 'readme') {
    visit(tree, 'table', visitor);
  }

  function visitor(node, index, parent) {
    /* Table. */
    var table = u('table', [
      u('tableRow', [
        u('tableCell', [u('text', 'Name')]),
        u('tableCell', [u('text', 'Description')]),
        u('tableCell', [u('text', 'License')])
      ])
    ]);

    /* Add the rows. */
    table.children = table.children.concat(
      dir(join(cwd, 'dictionaries'))
        .filter(negate(hidden))
        .map(function (name) {
          var url = 'dictionaries/' + name;
          var filePath = join(cwd, 'dictionaries', name, 'package.json');
          var pack = require(filePath);
          var license = [u('text', pack.license)];
          var description = pack.description.replace(/\sspelling.+$/, '');

          if (exists(join(cwd, 'dictionaries', name, 'LICENSE'))) {
            license = [u('link', {url: url + '/LICENSE'}, license)];
          }

          return u('tableRow', [
            u('tableCell', [u('strong', [
              u('link', {url: url}, [u('text', pack.name)])
            ])]),
            u('tableCell', [u('text', description)]),
            u('tableCell', license)
          ]);
        })
    );

    parent.children[index] = table;

    return false;
  }
}
