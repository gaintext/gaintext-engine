GainText
========

Overview
--------

GainText is about writing rich documents in an expressive and easy to learn language.

This repository contains a prototype parser for GainText documents.

See [gaintext.org](http://gaintext.org/) for more details.

[![Build Status](https://travis-ci.org/gaintext/gaintext-engine.svg?branch=master)](https://travis-ci.org/gaintext/gaintext-engine)


Design
------

The GainText document is parsed in several phases.

First the general structure of the document is parsed into a tree of blocks.
E.g. the content of a section or the cell of a table is each represented by one block.
This first structural parse uses a simple recursive descend parser.

Each block is considered as a document fragment and is parsed using the same parser.
This means that there is not one big parser which is responsible for all hierarchy levels.
Instead, each parser just identifies sub-blocks, without looking into the contents of that block.
This allows to use a different parsing context within each block.

Individual lines within each block are then parsed for embedded markup using
a packrat parser.
When parsing markup with embedded text (which in-turn may contain more markup),
then an end-marker parser is given to the parser of the embedded text.
The sub-parser only parses text until the end-marker matches.
Afterwards, the outer parser continues.
This allows to efficiently find ranges of text with markup.


Modules
-------

This repository contains several Swift modules:

* `Engine`: The basic parser engine.
* `Blocks`: Block-level parsers.
* `Markup`: Intra-line markup parsers.
* `Elements`: Definitions of special elements.
* `GainText`: Definition of the global scope for GainText documents.
* `gain`: The main function for the `gain` executable.


License
-------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.
If not, see [gnu.org/licenses](https://www.gnu.org/licenses/).
