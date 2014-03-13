# Orchestration of OpenStack deployment

## Assumptions

-   `Hostgroup`s are fully configured to provision Hosts (one `Hostgroup` for each `Staypuft::Role`).
-   Hosts are already associated to Hostgroups configured by the wizard.
-   `Host#build` flag is set to `false` so `Host` is assigned to `Hostgroup` without provisioning triggered. (Discovery plugin sets `build` to `true`.)
-   There is an order between `Hostgroup` defining the deployment dependency.
-   Dependencies between Services does not break the `Hostgroup` deployment order.

Meaning for April, we deploy the `Hostgroup`s in the given order and that should be all what is needed.

## Current status

_All action constants are in `Actions::Staypuft` namespace, omitting._

There is a `Hostgroup::OrderedDeploy` action which takes array of `Hostgroup`s as input and deploys (provisions and configures) all its `Host`s. This combined with the assumptions should serve as an implementation of the magic Deploy button.

There is also `Deployment::Deploy` action mock which wraps `Hostgroup::OrderedDeploy` further allowing to provide just `Staypuft::Deployment` object to the action.

_For now, tested just in my environment. Opening PR for comments and suggestions._

### Order of actions

Deploys all `Host`s in first given `Hostgroup` when all the `Host`s are deployed it moved to the next `Hostgroup` doing the same. Continues until all given `Hostgroup`s are deployed.

## How to test it

### Requirements

-   Working provisioning setup.
-   Defined two `Hostgroup`s which are able to provision `Host`s by setting just name, hostgroup, and compute_resource (tested with libvirt).

### Run

_temporary_

There is `app/lib/actions/staypuft/test.rb` file defining `Actions::Staypuft#test` and `#test2` methods to test the actions. _Please see the source code for methods signatures._

-   run console `rails c`
-   run `Actions::Staypuft#test` to provision just one host from one hostgroup
-   run `Actions::Staypuft#tes2` to provision 3 hosts from 2 different hostgroups in given order

The progress of the deployment can be mointored at:
-   ForemanTasks web UI <http://foreman.example.com/foreman_tasks/tasks>
-   Dynflow console <http://foreman.example.com/foreman_tasks/dynflow/>

