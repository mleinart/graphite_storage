Graphite\_Storage
================

A Ruby interface for accessing and modifying Graphite's storage formats

Here are some [whisper format details](http://readthedocs.org/docs/graphite/en/latest/whisper.html)
that I put together while writing this.

Differences with the Original Python Code
=========================================
A major difference between this library and the Python library that ships with Graphite is that the
Python libs always treat the Whisper database file as up to date and being accessed within the context
of the current time. This affects input validation (dates older than (now - max\_retention) are rejected),
storage behavior (archives older than the retention of earlier archives will not be stored) and data
retrieval (data from an old no longer updated Whisper file is not accessible).

Breaking this assumption lead to somewhat more confusing implementation and perhaps usage, but allows
more flexibility in accessing data.

Status
======
This is currently a first pass. It works for reading Whisper files, but write support has not yet been
implemented. The interface will likely change a few times before I begin cutting versions. Consider this
code *experimental* until this message is removed and gems are published.

Todo
====
* Add create/write support
* Add utility methods (resize, merge, etc)
* Add latest\_update search
* Refactor Archive#read and Archive#point\_span to be more clear

License and Author
==================

Author:: Michael Leinartas (<mleinartas@gmail.com>)

Copyright 2011, Michael Leinartas

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0]

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
