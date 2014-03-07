# Staypuft OpenStack Foreman Installer Plugin

Staypuft is the name of the OpenStack Foreman Installer plugin for The Foreman.

## Installation

See [How_to_Install_a_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)
for how to install Foreman plugins

Symlink `config/staypuft.local.rb` to yours Foreman `bundle.d`.

    ln -s ../../Staypuft/config/staypuft.local.rb staypuft.local.rb

## Enabling Puppet SSH

This is required for invoking puppet runs on remote machines.
This is needed in Staypuft for orchestration tasks.

### Enable Puppet Run (Based on Foreman 1.4.1)

Go to the foreman web UI.  

Administer -> Settings -> Puppet

Set Puppet Run to 'true'

### Configure Foreman Proxy

Add the following lines to the foreman proxy settings.yml

```
:puppet_provider: puppetssh
:puppetssh_sudo: false
:puppetssh_user: root
:puppetssh_keyfile: /etc/foreman-proxy/id_rsa
:puppetssh_command: /usr/bin/puppet agent --onetime --no-usecacheonfailure
```

### Create SSH Key fore foreman-proxy

```
# Create SSH Key using ssh-keygen

# cp private key to /etc/foreman-proxy/

chown foreman-proxy /etc/foreman-proxy/id_rsa

chmod 600 /etc/foreman-proxy/id_rsa
```

### Turn off StrictHostChecking for the foreman-proxy user

Create the following file:

<foreman HOME directory>/.ssh/config
```
Host *
    StrictHostKeyChecking no
```

N.B. This is a temporary solution.  We are tracking this issue here: http://projects.theforeman.org/issues/4543

### Distribute Foreman Public Key to Hosts

Add the id_rsa.pub public key to .ssh/authorized_keys file for user root on all Hosts

N.B. This is a temporary solution. We are tracking this issue here: http://projects.theforeman.org/issues/4542

### Restart foreman-proxy

sudo service foreman-proxy restart

## Usage

### Dynflow test from console

#### CREATE

Assuming that hostgroup is set up with all the necessary information to provision a host, a host provisioning can be triggered using Dynflow form console. E.g.

    result = ForemanTasks.trigger Actions::Staypuft::Host::Create,
                                  'rhel4',
                                  Hostgroup.find(8),
                                  ComputeResource.find(1)

#### PUPPET RUN

Assuming that host is created and running and you have enabled puppetssh.  See the section Enabling Puppet SSH.

    ForemanTasks.trigger Actions::Host::PuppetRun, Host.find(1)

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

