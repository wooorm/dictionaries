/**
 * @author Titus Wormer
 * @copyright 2015 Titus Wormer
 * @license MIT
 * @module dictionary:list-of-dictionaries
 * @fileoverview Generate a list of dictionaries for the README.
 */

'use strict';

/*
 * Dependencies.
 */

var fs = require('fs');
var path = require('path');
var escape = require('mdast-util-escape');
var visit = require('unist-util-visit');
var hidden = require('is-hidden');

/*
 * Methods.
 */

var dir = fs.readdirSync;
var exists = fs.existsSync;
var join = path.join;

/*
 * Values.
 */

var cwd = process.cwd();

/*
 * Table.
 */

var table = {
    'type': 'table',
    'align': [],
    'children': [
        {
            'type': 'tableHeader',
            'children': [
                {
                    'type': 'tableCell',
                    'children': [{
                        'type': 'text',
                        'value': 'Name'
                    }]
                },
                {
                    'type': 'tableCell',
                    'children': [{
                        'type': 'text',
                        'value': 'Description'
                    }]
                },
                {
                    'type': 'tableCell',
                    'children': [{
                        'type': 'text',
                        'value': 'License'
                    }]
                }
            ]
        }
    ]
}

/*
 * Add the rows.
 */

table.children = table.children.concat(
    dir(join(cwd, 'dictionaries'))
        .filter(function (fileName) {
            return !hidden(fileName)
        })
        .map(function (name) {
            var url = 'dictionaries/' + name;
            var filePath = join(cwd, 'dictionaries', name, 'package.json');
            var pack = require(filePath);
            var license = escape(pack.license);
            var description = pack.description.replace(/\sspelling.+$/, '');

            if (exists(join(cwd, 'dictionaries', name, 'LICENSE'))) {
                license = [{
                    'type': 'link',
                    'href': url + '/LICENSE',
                    'children': license
                }];
            }

            return {
                'type': 'tableRow',
                'children': [
                    {
                        'type': 'tableCell',
                        'children': [{
                            'type': 'strong',
                            'children': [{
                                'type': 'link',
                                'href': url,
                                'children': escape(pack.name)
                            }]
                        }]
                    },
                    {
                        'type': 'tableCell',
                        'children': escape(description)
                    },
                    {
                        'type': 'tableCell',
                        'children': license
                    }
                ]
            };
        })
)

/**
 * Transformer.
 *
 * Replaces the first `table` node in `readme.md`.
 *
 * @param {Node} tree - Syntax tree.
 * @param {VFile} file - Virtual file.
 */
function transformer(tree, file) {
    if (file.filePath() !== 'readme.md') {
        return;
    }

    visit(tree, 'table', function (node, index, parent) {
        parent.children[index] = table;
        return false;
    });
}

/**
 * Attacher.
 *
 * @return {Function} - `transformer`.
 */
function attacher() {
    return transformer;
}

/*
 * Expose.
 */

module.exports = attacher;
