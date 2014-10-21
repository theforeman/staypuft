# Staypuft data model

## Dictionary

-   **Deployment** - OpenStack deployment
-   **Layout** - OpenStack layout (e.g. HA with neutron)
-   **Role** - a role of nodes withing a given layout (e.g. OpenStack HA controllers)
-   **Service** - an OpenStack service (e.g. Keystone)

## Associations (roughly)

-   Deployment has one of the preconfigured Layouts
-   Layout has few Roles
-   Role has many Services
-   Service has many Puppetclasses (which are later applied to nodes in the role)

Foreman connections:

-   Deployment has one Hostgroup (child of preconfigured base_hostgroups)
-   There is a Hostgroup for each Role within given Deployment (parent is the hostgroup from previous point)
-   The host assigned to Hostgroup from previous point represent the nodes of the Role and Deployment from previous point.

# Staypuft installer

The [installer of Staypuft](https://github.com/theforeman/foreman-installer-staypuft) extends [foreman-installer](https://github.com/theforeman/foreman-installer) which is based on project [kafo](https://github.com/theforeman/kafo).

There are several steps:

-   Networking (Provisioning) wizard - asks user about networking in infrastructure
-   Authentication wizard - asks for (optional) ssh key and root password for provisioned hosts
-   Network configuration - configures $this_host 
-   Foreman installation - standard foreman-installer plus small custom modules to configure firewall and ntp
-   Puppet is run - to get OS data into DB
-   Provisioning data seed - configures foreman so it can provision hosts

## Networking wizard

It's an interactive CLI wizard collecting information about the environment for Staypuft installation. It collects network information required for provisioning

It also optionally (default: true) configures local networking based on the information given to the wizard and configures firewall (default: true) in Netowrking configuration step below based on these settings.

## Authentication wizard

You can view/set root password that will be set on every machine that will be provisioned from foreman. Also you can optionally add ssh public key that will be uploaded to root user on these hosts.

## Network configuration

If enabled, first puppet apply will be run to configure networking on $this_host. If you wrongly configured networking (usually own gateway parameter) you might lose networking. This extra puppet apply is required so we get fresh facts in next step.

## Puppet is run

It executes Foreman installation  [foreman-installer](https://github.com/theforeman/foreman-installer) feeding it information collected in previous step. This step also runs rake db:seed for the first time. This will seed most of staypuft default data: default Layouts,  Roles, Services. (SmartClassParametrs are not yet created because puppet modules are imported later.)

## Provisioning data seed

It runs puppet in --test mode so we get some initials data into foreman. First puppet run is printing out red warning with code 400 (usually users reports this as error, but it's expected). 

Then a rake task is run to import [quickstack](https://github.com/redhat-openstack/astapor/tree/master/puppet/modules) and [openstack-puppet-modules](https://github.com/redhat-openstack/openstack-puppet-modules) puppet classes.

Another step is run only on RHEL. You can configure you repository path (will be used as URL for installation medium) and subscription manager information. You can skip both but provisioning won't work unless you fix this manually in foreman. These credentials are stored as Operating System level parameters in foreman DB and are used in kickstart template during provisioning (snippet redhat_register)

Next it configures Foreman's infrastructure and hostgroup to allow OpenStack node deployment using [foreman_api](https://github.com/theforeman/foreman_api) gem. 

-   Global provisioning templates are changed to support OpenStack nodes.
-   Subnet is configured based on given information.
-   Installation media and partition table is created.
-   Operation system is created.
-   Partition table is updated and correctly association with OS
-   etc.
-   Base hostgroup is configured to use the infrastructure configured in previous steps

After this seeding through API another rake db:seed is run. Which skips previously created Layouts, Roles, Services, but it can now define SmartClassParameters because puppet modules are imported.

# Staypuft parameters' handling

Staypuft uses two types of Foreman's parameters:

-   **GroupParameters** - parameters on hostgroup (corresponding to a role in given deployment) are used to store values configured by user in the Staypuft UI wizard. 
-   **SmartClassParameters** - defined by Staypuft seed. Theirs values are defined by ERB snippets which uses values of GroupParameters. 

GroupParameters represent the high level user choices which are then used by the ERB snippets to generate all the parameters for the complex OpenStack puppet modules. [`app/lib/staypuft/seeder.rb`](https://github.com/theforeman/staypuft/blob/master/app/lib/staypuft/seeder.rb) defines the relationships between GroupParameters and SmartClassParameters.

# Deployment configuration

User creates a deployment and configures it using UI wizard which presents to user only high-level configuration parameters (GroupParameters). After user goes through the wizard he can also review and edit advanced parameters (SmartClassParameters). Deployment can be then deployed after hosts are assigned to hostgroups.

# Deployment

Deployment itself is orchestrated with [Dynflow](https://github.com/dynflow/dynflow) workflow engine. There is a Dynflow process which handles provisioning and configuration of the nodes in defined order. All role's nodes are provisioned and configured before moving to a next role. Within role there may be 3 different orders for nodes: sequential, parallel, leader (first node then all the remaining in parallel).

The nodes are orchestrated through provisioning initialization, there is ongoing work to be able to provision all the host at ones and orchestrate through puppet-run (puppetssh work).

# Key areas of the code

-   [installer of Staypuft](https://github.com/theforeman/foreman-installer-staypuft) - what is preconfigured for Staypuft
-   [`app/lib/staypuft/seeder.rb`](https://github.com/theforeman/staypuft/blob/master/app/lib/staypuft/seeder.rb) - how parameters tie to each other
-   [`app/models/staypuft/deployment`](https://github.com/theforeman/staypuft/tree/master/app/models/staypuft/deployment) - helpers for easy GroupParams access
-   [`app/lib/actions/staypuft`](https://github.com/theforeman/staypuft/tree/master/app/lib/actions/staypuft) - defines the Dynflow process of deploying