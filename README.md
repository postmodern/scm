# SCM

* [Source](http://github.com/postmodern/scm)
* [Issues](http://github.com/postmodern/scm/issues)
* [Documentation](http://rubydoc.info/gems/scm/frames)
* [Email](mailto:postmodern.mod3 at gmail.com)

## Description

{SCM} is a simple Ruby library for interacting with common SCMs,
such as Git, Mercurial (Hg) and SubVersion (SVN).

## Features

* Supports:
  * [Git](http://www.git-scm.org/)
  * [Mercurial (Hg)](http://mercurial.selenic.com/)
  * [SubVersion (SVN)](http://subversion.tigris.org/)
* Provides a basic {SCM::Repository API} for each SCM.

## Examples

    require 'scm'

    repo = SCM::Git.new('path/to/repo')

    repo.branches
    # => [...]

    repo.tags
    # => [...]

    repo.status
    # => {...}

    repo.log

## Install

    $ gem install scm

## Copyright

Copyright (c) 2011 Hal Brodigan

See {file:LICENSE.txt} for details.
