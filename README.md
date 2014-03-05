# Staypuft OpenStack Foreman Installer Plugin

Staypuft is the name of the OpenStack Foreman Installer plugin for The Foreman.

## Installation

See [How_to_Install_a_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)
for how to install Foreman plugins

Symlink `config/staypuft.local.rb` to yours Foreman `bundle.d`.

    ln -s ../../Staypuft/config/staypuft.local.rb staypuft.local.rb

## Usage

### Dynflow test from console

Assuming that hostgroup is set up with all the necessary information to provision a host, a host provisioning can be triggered using Dynflow form console. E.g.

    result = ForemanTasks.trigger Actions::Staypuft::Host::Create,
                                  'rhel4',
                                  Hostgroup.find(8),
                                  ComputeResource.find(1)

## TODO

Much to do:
* UI For launching a basic provisioning workflow,
* Deploy a 3-controller HA configuration,
* Configure an HA OpenStack deployment with three controller nodes and as many compute and storage nodes as are required,
* Configure an OpenStack deployment with a single controller node.

## Contributing

Fork and send a Pull Request. Thanks!

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

