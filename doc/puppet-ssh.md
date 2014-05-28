## Scenarios

### (1) Discovered hosts scenario

Assumptions:

-   Staypuft has full control over provisioning
-   Configured deployment already exists
-   Staypuft can execute puppetrun
    -   StrictHostKeyChecking set to `no`
-   all hosts have a module for managing puppet agent, lets call it `puppet-management-module`
    -   to be able to enable/disable puppet agent service just by changing param and re-running puppet

Steps:

-   Hosts are discovered
    -   by booting to Discovery image
-   Hosts are assigned to the deployment
    -   conversion to Host::Managed
    -   hosts are assigned to hostgroup
    -   build flag set to `true`
    -   environment set to `discovery` (to keep them booting to Discovery image)
-   Deployment is triggered
    -   all machines are provisioned
        -   environment is changed to `production`
        -   machines are restarted using SmartProxy running on the Discovery image
        -   puppet service is turned down
            -   needs altering of provisioning template
        -   authorized_key is set
            -   needs altering of provisioning template
    -   puppetrun is executed on hosts in order given by dependencies between roles
        -   triggered by orchestration
        -   executing puppetrun on hosts through proxy
    -   then on each machine puppet service is reenabled 
        -    by changing the param for `puppet-management-module`
    
### (2) Registered hosts scenario

Assumptions:

-   Staypuft doesn't have control over provisioning (DHCP) and cannot restart the machines
-   Configured deployment already exists
-   Auto-sign for the hosts is set [on proxy page](http://foreman.example.com/smart_proxies)

Steps:

-   staypuft installer generates answer-file for staypuft-client-installer
    -   including authorized key of `foreman-proxy` user from host running SmartProxy
-   staypuft-client-installer is executed on hosts
    -   puppet service is disabled
    -   adds authorized key for foreman-proxy to be able to execute commands
    -   registers the host to Staypuft
        -   hosts are managed, without hostgroup, in `discovery` environment
-   hosts are assigned to the deployment
    -   environment is set to `discovery` (if not set already)
    -   hosts are assigned to hostgroup    
-   Deployment is triggered
    -   one puppetrun in `discovery` environment to ensure puppet agent service is disabled using `puppet-management-module` (That is useful for host adding)
    -   environment is changed to `production`
    -   puppetrun is executed on hosts in order given by dependencies between roles
        -   same as in (1)
    -   then on each machine puppet service is reenabled (as in (1))

## Action items

-   [ ] **@ares** staypuft-client-installer
    -   [ ] disables puppet agent service
    -   [ ] registers the host
    -   [ ] registered host has to have `authorized_keys` set for foreman-proxy to be able to trigger puppetrun
    -   [x] configures puppetmaster using augeas (foreman's puppet module can't handle that easily)
-   [ ] staypuft installer 
    -   [ ] **@ares** must generate answer file for client installer and print out instructions
    -   [ ] has to generate key for foreman-proxy user on host hosting the SmartProxy
    -   [ ] has to set `StrictHostKeyChecking no` because foreman proxy does not know all the hosts
    -   [ ] has to enable puppetrun
    -   [ ] **@pitr-ch** edit provisioning template not to start puppet agent service
    -   [ ] **@pitr-ch** discovered host has to have `authorized_keys` set for foreman-proxy to be able to trigger puppetrun, provision_template should be updated
-   [ ] **@mtaylor** find suitable or write one `puppet-management-module`
-   [ ] update orchestration actions to reflect new process
    -   [ ] detection discovered vs registered
    -   [ ] reenabling the puppet agent service, check that only that changed, fail otherwise
    -   [ ] the opposite: ensures puppet agent service is disabled, uses puppet-manage-module
    -   [ ] update the process

**Nice to have:**

-   [ ] distribute host keys to foreman-proxy so `StrictHostKeyChecking no` can be disabled
