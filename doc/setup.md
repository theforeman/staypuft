# Steps to get a dev env for Staypuft development

_Based on pchalupa's setup, if you find a bug/problem ping me irc \#theforeman-dev channel._

## Architecture

Bare-metal machine with: smart-proxy, puppet master, foreman, kvm,
(virsh with dhcp and dns support on proxy).
VMs provisioned in virtual network. Foreman web server process replaced,
redirected in Apache to thin running form checkout with Staypuft.

## Foreman

### Installation

-   fresh Fedora 19 on bare-metal
-   `yum -y install http://yum.theforeman.org/releases/1.5/f19/x86_64/foreman-release.rpm`
-   `yum -y install foreman-installer`
-   `yum -y install foreman-libvirt`
-   disabled selinux `setenforce` and edit `/etc/sysconfig/selinux`

-   allow ports in firewall
    _I've used F19 firewall config tool:_ `firewall-config`
    -   enable in zone public
        -   services: http, https, libvirt
        -   ports: 8140 (puppetmaster), 8443 (proxy), 5900-5930 (vnc)

-   install `yum install @virtualization`
-   create/update subnet `sudo virsh net-edit default`

        <network>
          <name>default</name>
          <uuid>7c58ee26-2c78-4b4c-be8d-2d7f1ce9b4f8</uuid>
          <forward mode='nat'>
            <nat>
              <port start='1024' end='65535'/>
            </nat>
          </forward>
          <bridge name='virbr0' stp='on' delay='0' />
          <mac address='52:54:00:e4:89:49'/>
          <domain name='example.com'/>
          <ip address='192.168.100.1' netmask='255.255.255.0'>
            <tftp root='/var/lib/tftpboot/' />
            <dhcp>
              <range start='192.168.100.10' end='192.168.100.254' />
              <bootp file='pxelinux.0' />
            </dhcp>
          </ip>
        </network>

-   set fqdn of the bare-metal machine to foreman.example.com
    -   `hostname foreman.example.com`
    -   update `/etc/hostname`
    -   add `192.168.100.1 foreman.example.com foreman` line to
         `/etc/hosts`

-   fix non ASCI chars in `/etc/fedora-release` and if it exists
    `/etc/fedoraversion` replace ö with o and also remove the ' char.  
-   run `foreman-installer` (to install foreman with default options)
    -   _use system ruby; rvm and rbenv can mess things up_
    -   _If you get locale errors or related to operatingsystem version
        check:_ `export LANG=en_GB.utf8`
    -   _If you get the error:_ 
        `/Stage[main]/Foreman_proxy::Register/Foreman_smartproxy[martyn-work-laptop.example.com]: Could not evaluate: 404 Resource Not Found: <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">` 
        try:
          -   setenforce 0
          -   service httpd restart
          -   forman-install
          -   see: <https://groups.google.com/forum/#!msg/foreman-users/KLLYmqS0aD4/OkoTfdDe8DsJ>

### Configuration

-   enable access to libvirt
    <http://theforeman.org/manuals/1.5/index.html#5.2.5LibvirtNotes>
    -   test connection from foreman UI
        <https://foreman.example.com/compute_resources/1-libvirt/edit>
        `Test Connection` button

-   configure smart proxy with tftp, dhcp, dns
    <http://theforeman.org/manuals/1.5/index.html#4.3.9Libvirt>
    -   refresh Features on the smart proxy record

-   see http://www.youtube.com/watch?v=eHjpZr3GB6s about how setup
    provisioing in the foreman UI, basically linking all together

-   DNS setup
    -   VMs see foreman.example.com and each other because of dnsmasq
        run by libvirt and managed by foreman-proxy
    -   to set up local dnsmasq to see VMs from the foreman.example.com
        machine
        -   add `dns=dnsmasq` to `/etc/NetworkManager/NetworkManager.conf`
            to enable global dnsmasq
        -   add file `/etc/NetworkManager/dnsmasq.d/global.conf` containing

                # to only listen on local network and not to colide with libvirt dnsmasqs
                listen-address=127.0.0.1
                server=/example.com/192.168.100.1

        -   restart NetworkManager `systemctl restart NetworkManager.service`
        -   _sources <http://wiki.libvirt.org/page/Libvirtd_and_dnsmasq>_


## Redirecting all traffic to other foreman web process running from git checkout

-   update httpd foreman config files both `/etc/httpd/conf.d/05-foreman.conf` and `05-foreman-ssl.conf`

        # replace following line
        PassengerAppRoot /usr/share/foreman
        
        # with following:
        # PassengerAppRoot /usr/share/foreman
        LoadModule proxy_module modules/mod_proxy.so
        LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
        LoadModule proxy_http_module modules/mod_proxy_http.so
        
        <Proxy balancer://thinserversforeman>
          BalancerMember http://your.machine:3000/ # use fqdn not localhost
        </Proxy>
        
        RewriteEngine On
        # RewriteCond %{REQUEST_URI} !^/pulp.*$ # needed when installed with Katello
        RewriteRule ^/(.*)$ balancer://thinserversforeman%{REQUEST_URI} [P,QSA,L]

-   Use same DB or copy to the other machine.
-   check the settings of your new foreman process: modulepath, foreman_url,
    ssl_ca_file, ssl_certificate, ssl_priv_key, unattended_url

## Importing astapor puppet modules

Configure `/etc/puppet/puppet.conf` to point to openstack-puppet-modules and astapor modules.

-   Check out astapor and openstack-puppet-modules 
    -   from `git@github.com:redhat-openstack/astapor.git` and
    -   from `git@github.com:redhat-openstack/openstack-puppet-modules.git`
        (use `git clone --recursive ...` to initialize the submodules).
-   Modify the `[production]` `/modulepath` section of `/etc/puppet/puppet.conf`:

        [production]
        modulepath     = /etc/puppet/environments/production/modules:/etc/puppet/environments/common:/usr/share/puppet/modules:/{git-root}/openstack-puppet-modules:{git-root}/astapor/puppet/modules

-   `rake puppet:import:puppet_classes[batch]` alternatively use `foreman-rake` when on rpm version

## Foreman Discovery setup

-   the plugin it is a dependency of Staypuft _when #39 is merged_
-   install tftp images, on the machine with proxy execute:
    -   `cd /var/lib/tftpboot/boot`
    -   `wget http://yum.theforeman.org/discovery/releases/0.3/discovery-prod-0.3.0-1-initrd.img`
    -   `wget http://yum.theforeman.org/discovery/releases/0.3/discovery-prod-0.3.0-1-vmlinuz`
-   turn off setting Provisioning/`safemode_render` for `<%= Setting['foreman_url'] %>` to work
-   change PXELinux global default template to following

        <%#
          kind: PXELinux
          name: Community PXE Default
        %>
        
        <%# This template has special name (do not change it) and it is used for booting unknown hosts. %>
        
        DEFAULT menu
        PROMPT 0
        MENU TITLE PXE Menu
        TIMEOUT 200
        TOTALTIMEOUT 6000
        ONTIMEOUT discovery
        
        LABEL discovery
        MENU LABEL Foreman Discovery
        KERNEL boot/discovery-prod-0.3.0-1-vmlinuz
        APPEND rootflags=loop initrd=boot/discovery-prod-0.3.0-1-initrd.img root=live:/foreman.iso rootfstype=auto ro rd.live.image rd.live.check rd.lvm=0 rootflags=ro crashkernel=128M elevator=deadline max_loop=256 rd.luks=0 rd.md=0 rd.dm=0 foreman.url=<%= Setting['foreman_url'] %> nomodeset selinux=0 stateless
-   build PXE default
-   foreman web process has to have access to discovered hosts by IP adresses, 
    if the foreman web process is running on the same machine as the virtual network then all is good, otherwise:
    -   set static routes from machine with foreman web process to the virtual network
        `sudo route -n add 192.168.100.0/24 foreman.example.com`
    -   update iptables on machine hosting the virtual network
        -   enable logging of TRACE target `modprobe ipt_LOG`
        -   add `kern.debug /var/log/iptables` to `/etc/rsyslog.conf`
        -   restart `systemctl restart rsyslog.service`
        -   add rule to trace the incoming packet
            `iptables -A PREROUTING -t raw --source 10.34.131.187 --destination 192.168.100.53 -j TRACE`
        -   try to access a machine on private network
        -   look into `/var/log/iptables` which rule REJECTed the packet
        -   add rule ACCEPTing the packets above the rejecting rule
            in my case `iptables -t filter -I FORWARD 15 -o virbr0 -s 10.34.131.187 -j ACCEPT` 
            before the rejecting one in FORWARD chain 
            `REJECT     all  --  *      virbr0  0.0.0.0/0            0.0.0.0/0            reject-with icmp-port-unreachable`
        -   TODO make static routes and iptable changes permanent
-   create a machine in libvirt and let it be discovered

## Create a provision kick start file for open stack:

-   Host -> Provisioning Templates -> New Template
-   Add the following
    -   Name: Kickstart OpenStack
    -   Content: 
        <https://gist.githubusercontent.com/mtaylor/9669224/raw/090f2af39939c7fff03d04da4abff6ea7d35510e/gistfile1.rb>
    -   Type: provisioning
    -   Association: <to your OS>

-   Host -> Operating Systems -> <your OS> -> Templates
    -   provisioning: Kickstart OpenStack
    -   Override parrameters with the controller IP: `controller_admin_host`, `controller_priv_hos`, `controller_pub_host`, `mysql_host`, `qpid_host`

## Enabling Puppet SSH

This is required for invoking puppet runs on remote machines.
This will be needed in future versions of Staypuft for orchestration tasks.

-   Enable Puppet Run
    -   Go to the foreman web UI.
        Administer -> Settings -> Puppet
    -   Set Puppet Run to 'true'

-   Configure Foreman Proxy
    -   Add the following lines to the foreman proxy settings.yml

            :puppet_provider: puppetssh
            :puppetssh_sudo: false
            :puppetssh_user: root
            :puppetssh_keyfile: /etc/foreman-proxy/id_rsa
            :puppetssh_command: /usr/bin/puppet agent --onetime --no-usecacheonfailure

        Taken from <http://projects.theforeman.org/projects/smart-proxy/repository/revisions/13ed47120944776d31a63386b650bb796462f896/diff/config/settings.yml.example>.

-   Create SSH Key fore foreman-proxy

        # Create SSH Key using ssh-keygen
        # cp private key to /etc/foreman-proxy/
        chown foreman-proxy /etc/foreman-proxy/id_rsa
        chmod 600 /etc/foreman-proxy/id_rsa

-   Turn off StrictHostChecking for the foreman-proxy user
    -   Create the following file: `<foreman HOME directory>/.ssh/config`

            Host *
                StrictHostKeyChecking no

    -   _This is a temporary solution.  We are tracking this issue here: <http://projects.theforeman.org/issues/4543>_

-   Distribute Foreman Public Key to Hosts
    -   Add the id_rsa.pub public key to .ssh/authorized_keys file for user root on all Hosts
    -   _This is a temporary solution. We are tracking this issue here: <http://projects.theforeman.org/issues/4542>_

-   Restart foreman-proxy, `sudo service foreman-proxy restart`

