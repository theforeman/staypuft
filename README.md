# Staypuft OpenStack Foreman Installer Plugin

Staypuft is the name of the OpenStack Foreman Installer plugin for The Foreman.

## Installation

See [How_to_Install_a_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)
for how to install Foreman plugins

Symlink `config/staypuft.local.rb` to yours Foreman `bundle.d`.

    ln -s ../../Staypuft/config/staypuft.local.rb staypuft.local.rb

## Development setup

See [this](doc/setup.md) document.

## Contributing

Fork and send a Pull Request. Thanks!

## Release a new version

To release a new gem version you have to be owner of the gem on rubygems.org. 
If you're not you can ask for ownership or you can build a gem locally. To build 
a gem locally, cd into staypuft directory and run `rake build`. This builds
a gem in pkg directory. The version is determined by constant in lib/staypuft/version.rb 
so if you want to bump version, modify this file before running rake.

If you are the owner and you want to release new gem version, make sure you're building
from official repository (not your own fork). Clone the repository and make sure the origin
remote is github.com/theforeman/staypuft. Now bump the version in lib/staypuft/version.rb.
Finally build and release new gem by running `rake release`. This will build the package,
tag the commit, push the commit and the tag to origin and uploads the gem to rubygems.org.

To build and RPM we recommend using our specs in [Foreman packaging](https://github.com/theforeman/foreman-packaging).
You should find the spec in rpm/develop branch. There's also a README.md which explains
how you should update and build a package. Long story short, you update the gem and spec,
send and send a PR. Once it's merged you can build in our koji instance (if you have
access) using tito.

## Copyright

Copyright (c) 2014 Red Hat, Inc. http://redhat.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

