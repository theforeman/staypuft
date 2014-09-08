require 'facter'

module Staypuft
  class Seeder

    # FIXME: this is the list pulled as-is from astapor. Any changes for staypuft are not
    # yet in place. In addition, I don't know if we want to break these down by
    # Role, or leave them in one big list (internally they get set per puppetclass)
    ASTAPOR_PARAMS = {
        'verbose'                      => 'true',
        'heat_cfn'                     => 'false',
        'heat_cloudwatch'              => 'false',
        'ceilometer'                   => 'true',
        'ceilometer_host'              => 'false',
        'glance_gluster_peers'         => [],
        'glance_gluster_volume'        => 'glance',
        'glance_gluster_replica_count' => '3',
        'gluster_open_port_count'      => '10',
        'nova_default_floating_pool'   => 'nova',
        'swift_all_ips'                => %w(192.168.203.1 192.168.203.2 192.168.203.3 192.168.203.4),
        'swift_ext4_device'            => '/dev/sdc2',
        'swift_local_interface'        => 'eth3',
        'swift_loopback'               => true,
        'mysql_virtual_ip'             => '192.168.200.220',
        'mysql_bind_address'           => '0.0.0.0',
        'mysql_virt_ip_nic'            => 'eth1',
        'mysql_virt_ip_cidr_mask'      => '24',
        'mysql_shared_storage_device'  => '192.168.203.200:/mnt/mysql',
        'mysql_shared_storage_type'    => 'nfs',
        'mysql_resource_group_name'    => 'mysqlgrp',
        'mysql_clu_member_addrs'       => '192.168.203.11 192.168.203.12 192.168.203.13',
        'amqp_username'                => 'openstack',
        'admin_email'                  => "admin@#{Facter.value(:domain)}",
        'enable_ovs_agent'             => 'true',
        'ovs_vxlan_udp_port'           => '4789',
        'auto_assign_floating_ip'      => 'true',
        'cisco_vswitch_plugin'         => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
        'cisco_nexus_plugin'           => 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin',
        'nexus_config'                 => { :hash => {}},
        'nexus_credentials'            => [],
        'provider_vlan_auto_create'    => 'false',
        'provider_vlan_auto_trunk'     => 'false',
        'backend_server_names'         => [],
        'backend_server_addrs'         => [],
        'configure_ovswitch'           => 'true',
        'neutron'                      => 'false',
        'ssl'                          => 'false',
        'freeipa'                      => 'false',
        'mysql_ca'                     => '/etc/ipa/ca.crt',
        'mysql_cert'                   => '/etc/pki/tls/certs/PRIV_HOST-mysql.crt',
        'mysql_key'                    => '/etc/pki/tls/private/PRIV_HOST-mysql.key',
        'amqp_ca'                      => '/etc/ipa/ca.crt',
        'amqp_cert'                    => '/etc/pki/tls/certs/PRIV_HOST-amqp.crt',
        'amqp_key'                     => '/etc/pki/tls/private/PRIV_HOST-amqp.key',
        'horizon_ca'                   => '/etc/ipa/ca.crt',
        'horizon_cert'                 => '/etc/pki/tls/certs/PUB_HOST-horizon.crt',
        'horizon_key'                  => '/etc/pki/tls/private/PUB_HOST-horizon.key',
        'use_qemu_for_poc'             => 'false',
    }

    # key (:ha, etc) is only  used internally for referencing from roles
    LAYOUTS        = { :ha_nova        => { :name       => 'High Availability Controllers / Compute',
                                            :networking => 'nova' },
                       :non_ha_nova    => { :name       => 'Controller / Compute',
                                            :networking => 'nova' },
                       :ha_neutron     => { :name       => 'High Availability Controllers / Compute',
                                            :networking => 'neutron' },
                       :non_ha_neutron => { :name       => 'Controller / Compute',
                                            :networking => 'neutron' } }

    # some services don't have puppetclasses yet, since they aren't broken out on the back end
    SERVICES       = {
        :non_ha_amqp        => { :name => 'AMQP (non-HA)', :class => [] },
        :mysql              => { :name => 'MySQL', :class => [] },
        :non_ha_keystone    => { :name => 'Keystone (non-HA)', :class => [] },
        :nova_controller    => { :name => 'Nova (Controller)', :class => [] },
        :neutron_controller => { :name => 'Neutron (Controller)', :class => [] },
        :non_ha_glance      => { :name => 'Glance (non-HA)', :class => [] },
        :cinder_controller  => { :name => 'Cinder (controller)', :class => [] },
        :cinder_node        => { :name => 'Cinder (node)', :class => ['quickstack::storage_backend::cinder'] },
        :heat               => { :name => 'Heat', :class => [] },
        :ceilometer         => { :name => 'Ceilometer', :class => [] },
        :neutron_networker  => { :name => 'Neutron Networker', :class => ['quickstack::neutron::networker'] },
        :nova_compute       => { :name => 'Nova-compute', :class => ['quickstack::nova_network::compute'] },
        :neutron_compute    => { :name => 'Neutron-compute', :class => ['quickstack::neutron::compute'] },
        :swift              => { :name => 'Swift (node)', :class => ['quickstack::swift::storage'] },
        :ha_controller      => { :name  => 'HA (Controller)',
                                 :class => ['quickstack::openstack_common',
                                            'quickstack::pacemaker::common',
                                            'quickstack::pacemaker::params'] },
        :keystone_ha        => { :name  => 'Keystone (HA)',
                                 :class => ['quickstack::pacemaker::keystone'] },
        :load_balancer_ha   => { :name  => 'Load Balancer (HA)',
                                 :class => ['quickstack::pacemaker::load_balancer'] },
        :memcached_ha       => { :name  => 'Memcached (HA)',
                                 :class => ['quickstack::pacemaker::memcached'] },
        :qpid_ha            => { :name => 'qpid (HA)', :class => ['quickstack::pacemaker::qpid'] },
        :glance_ha          => { :name => 'Glance (HA)', :class => ['quickstack::pacemaker::glance'] },
        :nova_ha            => { :name => 'Nova (HA)', :class => ['quickstack::pacemaker::nova'] },
        :heat_ha            => { :name => 'Heat (HA)', :class => ['quickstack::pacemaker::heat'] },
        :cinder_ha          => { :name => 'Cinder (HA)', :class => ['quickstack::pacemaker::cinder'] },
        :swift_ha           => { :name => 'Swift (HA)', :class => ['quickstack::pacemaker::swift'] },
        :horizon_ha         => { :name => 'Horizon (HA)', :class => ['quickstack::pacemaker::horizon'] },
        :galera_ha          => { :name => 'Galera (HA)', :class => ['quickstack::pacemaker::galera'] },
        :mysql_ha           => { :name => 'Mysql (HA)', :class => ['quickstack::pacemaker::mysql'] },
        :neutron_ha         => { :name => 'Neutron (HA)', :class => ['quickstack::pacemaker::neutron'] },
        :generic_rhel_7     => { :name => 'Generic RHEL 7', :class => ['quickstack::openstack_common'] },
        :ceph_osd           => { :name => 'Ceph Storage (OSD) (node)', :class => ['quickstack::openstack_common'] },
    }

    # The list of roles is still from astapor
    # FIXME for now layouts are different based on Nova vs. Neutron networks. This is
    #  actually incorrect, but it's a placeholder example of how layouts might differ
    # until we get the real list of roles per layout
    # layout refs below specify layout keys from layouts hash
    ROLES          = [
        { :name          => 'Controller (Nova)',
          :class         => 'quickstack::nova_network::controller',
          :layouts       => [[:non_ha_nova, 1]],
          :services      => [:non_ha_amqp, :mysql, :non_ha_keystone, :nova_controller, :non_ha_glance,
                             :cinder_controller, :heat, :ceilometer],
          :orchestration => 'concurrent' },
        { :name          => 'Compute (Nova)',
          :class         => [],
          :layouts       => [[:ha_nova, 10], [:non_ha_nova, 10]],
          :services      => [:nova_compute],
          :orchestration => 'leader' },
        { :name          => 'Controller (Neutron)',
          :class         => 'quickstack::neutron::controller',
          :layouts       => [[:non_ha_neutron, 1]],
          :services      => [:non_ha_amqp, :mysql, :non_ha_keystone, :neutron_controller, :non_ha_glance,
                             :cinder_controller, :heat, :ceilometer],
          :orchestration => 'concurrent' },
        { :name          => 'Compute (Neutron)',
          :class         => [],
          :layouts       => [[:ha_neutron, 10], [:non_ha_neutron, 10]],
          :services      => [:neutron_compute],
          :orchestration => 'concurrent' },
        { :name          => 'Neutron Networker',
          :class         => [],
          :layouts       => [[:non_ha_neutron, 3]],
          :services      => [:neutron_networker],
          :orchestration => 'concurrent' },
        { :name          => 'Cinder Block Storage',
          :class         => [],
          :layouts       => [],
          :services      => [:cinder_node],
          :orchestration => 'concurrent' },
        { :name          => 'Swift Storage Node',
          :class         => [],
          :layouts       => [],
          :services      => [:swift],
          :orchestration => 'concurrent' },
        { :name          => 'HA Controller',
          :class         => [],
          :layouts       => [[:ha_nova, 1], [:ha_neutron, 1]],
          :services      => [:ha_controller, :keystone_ha, :load_balancer_ha, :memcached_ha, :qpid_ha,
                             :glance_ha, :nova_ha, :heat_ha, :cinder_ha, :swift_ha, :horizon_ha, :mysql_ha,
                             :neutron_ha, :galera_ha],
          :orchestration => 'concurrent' },
        { :name          => 'Generic RHEL 7',
          :class         => '',
          :layouts       => [[:non_ha_nova, 20],[:non_ha_neutron, 20], [:ha_nova, 20], [:ha_neutron, 20]],
          :services      => [:generic_rhel_7],
          :orchestration => 'concurrent' },
        { :name          => 'Ceph Storage Node (OSD)',
          :class         => '',
          :layouts       => [[:non_ha_nova, 20], [:non_ha_neutron, 20], [:ha_nova, 20], [:ha_neutron, 20]],
          :services      => [:ceph_osd],
          :orchestration => 'concurrent' },
      ]

    CONTROLLER_ROLES = ROLES.select { |h| h.fetch(:name) =~ /Controller/ }
    CEPH_ROLES = ROLES.select {|h| h.fetch(:name) =~ /Ceph/ }

    ALL_LAYOUTS = LAYOUTS.keys
    SUBNET_TYPES = { :pxe             => { :name     => Staypuft::SubnetType::PXE,
                                           :required => true,
                                           :layouts  => ALL_LAYOUTS},
                     :management      => { :name     => Staypuft::SubnetType::MANAGEMENT,
                                           :required => true,
                                           :layouts  => ALL_LAYOUTS},
                     :external        => { :name     => Staypuft::SubnetType::EXTERNAL,
                                           :required => true,
                                           :layouts  => ALL_LAYOUTS},
                     :cluster_mgmt    => { :name     => Staypuft::SubnetType::CLUSTER_MGMT,
                                           :required => true,
                                           :layouts  => ALL_LAYOUTS},
                     :admin_api       => { :name     => Staypuft::SubnetType::ADMIN_API,
                                           :required => true,
                                           :layouts  => ALL_LAYOUTS},
                     :public_api      => { :name     => Staypuft::SubnetType::PUBLIC_API,
                                           :required => true,
                                           :layouts  => ALL_LAYOUTS},
                     :tenant          => { :name     => Staypuft::SubnetType::TENANT,
                                           :required => true,
                                           :layouts  => ALL_LAYOUTS},
                     :storage         => { :name     => Staypuft::SubnetType::STORAGE,
                                           :required => false,
                                           :layouts  => ALL_LAYOUTS},
                     :storage_cluster => { :name     => Staypuft::SubnetType::STORAGE_CLUSTERING,
                                           :required => false,
                                           :layouts  => ALL_LAYOUTS}
    }

    def get_host_format(param_name, subnet_type_name)
      { :string => "<%= d = @host.deployment; d.ha? ? d.network_query.get_vip(:#{param_name}) : d.network_query.controller_ip('#{subnet_type_name}') %>" }
    end

    # virtual ip addresses
    def vip_format(param_name)
      { :string => '<%%= @host.deployment.network_query.get_vip(:%s) %%>' % param_name }
    end

    def functional_dependencies
      amqp_provider               = { :string => '<%= @host.deployment.amqp_provider %>' }
      neutron                     = { :string => '<%= @host.deployment.neutron_networking? %>' }
      ceilometer                  = { :string => '<%= @host.deployment.non_ha? %>' }

      # Nova
      network_manager             = { :string => '<%= @host.deployment.nova.network_manager %>' }
      # multi_host handled inline, since it's two separate static values 'true' and 'True'
      network_overrides           = { :hash =>   '<%= @host.deployment.nova.network_overrides %>' }
      network_num_networks        = { :string => '<%= @host.deployment.nova.num_networks %>' }
      network_fixed_range         = { :string => '<%= @host.deployment.nova.private_fixed_range %>' }
      network_floating_range      = { :string => '<%= @host.deployment.nova.public_floating_range %>' }
      network_private_iface       = { :string => "<%= @host.deployment.network_query.interface_for_host(@host, '#{Staypuft::SubnetType::TENANT}') %>" }
      network_public_iface        = { :string => "<%= @host.deployment.network_query.interface_for_host(@host, '#{Staypuft::SubnetType::EXTERNAL}') %>" }
      network_create_networks     = true

      # Neutron
      ovs_vlan_ranges             = { :array =>  '<%= @host.deployment.neutron.networker_vlan_ranges %>' }
      compute_ovs_vlan_ranges     = { :array =>  '<%= @host.deployment.neutron.compute_vlan_ranges %>' }
      ml2_network_vlan_ranges     = ovs_vlan_ranges
      tenant_network_type         = '<%= @host.deployment.neutron.network_segmentation %>'
      ml2_tenant_network_types    = [ tenant_network_type ]
      ml2_tunnel_id_ranges        = ['10:1000']
      ml2_vni_ranges              = ['10:1000']
      ovs_tunnel_types            = ['vxlan', 'gre']
      ovs_tunnel_iface            = { :string => '<%= n = @host.deployment.neutron; n.enable_tunneling? ? n.tenant_iface(@host) : "" %>' }
      ovs_bridge_mappings         = { :array =>  '<%= @host.deployment.neutron.networker_ovs_bridge_mappings(@host) %>' }
      ovs_bridge_uplinks          = { :array =>  '<%= @host.deployment.neutron.networker_ovs_bridge_uplinks(@host) %>' }
      compute_ovs_tunnel_iface    = { :string => '<%= n = @host.deployment.neutron; n.enable_tunneling? ? n.tenant_iface(@host) : "" %>' }
      compute_ovs_bridge_mappings = { :array =>  '<%= @host.deployment.neutron.compute_ovs_bridge_mappings(@host) %>' }
      compute_ovs_bridge_uplinks  = { :array =>  '<%= @host.deployment.neutron.compute_ovs_bridge_uplinks(@host) %>' }
      enable_tunneling            = { :string => '<%= @host.deployment.neutron.enable_tunneling?.to_s %>' }

      # Glance
      backend                     = { :string => '<%= @host.deployment.glance.backend %>' }
      pcmk_fs_type                = { :string => '<%= @host.deployment.glance.pcmk_fs_type %>' }
      pcmk_fs_device              = { :string => '<%= @host.deployment.glance.pcmk_fs_device %>' }
      pcmk_fs_dir                 = '/var/lib/glance/images'
      pcmk_fs_manage              = { :string => '<%= @host.deployment.glance.pcmk_fs_manage %>' }
      pcmk_fs_options             = { :string => '<%= @host.deployment.glance.pcmk_fs_options %>' }
      glance_rbd_store_user       = 'images'
      glance_rbd_store_pool       = 'images'

      # Cinder
      volume                      = true
      cinder_backend_gluster      = false
      cinder_backend_gluster_name = 'gluster_backend'
      cinder_backend_iscsi        = { :string => '<%= @host.deployment.cinder.lvm_backend? %>' }
      cinder_backend_iscsi_name   = 'iscsi_backend'
      cinder_backend_nfs          = { :string => '<%= @host.deployment.cinder.nfs_backend? %>' }
      cinder_backend_nfs_name     = 'nfs_backend'
      cinder_multiple_backends    = { :string => '<%= @host.deployment.cinder.multiple_backends? %>' }
      cinder_nfs_shares           = ['<%= @host.deployment.cinder.nfs_uri %>']
      cinder_nfs_mount_options    = 'nosharecache'

      cinder_backend_rbd                      = { :string => '<%= @host.deployment.cinder.ceph_backend? %>' }
      cinder_backend_rbd_name                 = 'rbd_backend'
      cinder_rbd_pool                         = 'volumes'
      cinder_rbd_ceph_conf                    = '/etc/ceph/ceph.conf'
      cinder_rbd_flatten_volume_from_snapshot = 'false'
      cinder_rbd_max_clone_depth              = '5'
      cinder_rbd_user                         = 'volumes'
      cinder_rbd_secret_uuid                  = { :string => '<%= @host.deployment.cinder.rbd_secret_uuid %>' }

      cinder_backend_eqlx           = { :string => '<%= @host.deployment.cinder.equallogic_backend? %>' }
      cinder_backend_eqlx_name      = ['eqlx_backend']
      # TODO: confirm these params and add them to model where user input is needed
      # below dynamic calls are commented out since the model does not yet have san/chap entries
      cinder_san_ip                 = { :array => '<%= @host.deployment.cinder.compute_eqlx_san_ips %>' }
      cinder_san_login              = { :array => '<%= @host.deployment.cinder.compute_eqlx_san_logins %>' }
      cinder_san_password           = { :array => '<%= @host.deployment.cinder.compute_eqlx_san_passwords %>' }
      cinder_eqlx_group_name        = { :array => '<%= @host.deployment.cinder.compute_eqlx_group_names %>' }
      cinder_eqlx_pool              = { :array => '<%= @host.deployment.cinder.compute_eqlx_pools %>'}

      cinder_san_thin_provision     = ['false']
      cinder_eqlx_use_chap          = ['false']
      cinder_eqlx_chap_login        = ['']
      cinder_eqlx_chap_password     = ['']

      # Keystone
      keystonerc = 'true'

      # effective_value grabs shared password if deployment is in shared password mode,
      # otherwise use the service-specific one
      admin_pw                      = { :string => '<%= @host.deployment.passwords.effective_value(:admin) %>' }
      ceilometer_user_pw            = { :string => '<%= @host.deployment.passwords.effective_value(:ceilometer_user) %>' }
      cinder_db_pw                  = { :string => '<%= @host.deployment.passwords.effective_value(:cinder_db) %>' }
      cinder_user_pw                = { :string => '<%= @host.deployment.passwords.effective_value(:cinder_user) %>' }
      glance_db_pw                  = { :string => '<%= @host.deployment.passwords.effective_value(:glance_db) %>' }
      glance_user_pw                = { :string => '<%= @host.deployment.passwords.effective_value(:glance_user) %>' }
      heat_db_pw                    = { :string => '<%= @host.deployment.passwords.effective_value(:heat_db) %>' }
      heat_user_pw                  = { :string => '<%= @host.deployment.passwords.effective_value(:heat_user) %>' }
      heat_cfn_user_pw              = { :string => '<%= @host.deployment.passwords.effective_value(:heat_cfn_user) %>' }
      keystone_db_pw                = { :string => '<%= @host.deployment.passwords.effective_value(:keystone_db) %>' }
      keystone_user_pw              = { :string => '<%= @host.deployment.passwords.effective_value(:keystone_user) %>' }
      mysql_root_pw                 = { :string => '<%= @host.deployment.passwords.effective_value(:mysql_root) %>' }
      neutron_db_pw                 = { :string => '<%= @host.deployment.passwords.effective_value(:neutron_db) %>' }
      neutron_user_pw               = { :string => '<%= @host.deployment.passwords.effective_value(:neutron_user) %>' }
      nova_db_pw                    = { :string => '<%= @host.deployment.passwords.effective_value(:nova_db) %>' }
      nova_user_pw                  = { :string => '<%= @host.deployment.passwords.effective_value(:nova_user) %>' }
      swift_admin_pw                = { :string => '<%= @host.deployment.passwords.effective_value(:swift_admin) %>' }
      swift_user_pw                 = { :string => '<%= @host.deployment.passwords.effective_value(:swift_user) %>' }
      amqp_pw                       = { :string => '<%= @host.deployment.passwords.effective_value(:amqp) %>' }
      amqp_nssdb_pw                 = { :string => '<%= @host.deployment.passwords.effective_value(:amqp_nssdb) %>' }
      keystone_admin_token          = { :string => '<%= @host.deployment.passwords.effective_value(:keystone_admin_token) %>' }

      #these don't share the user-supplied password value; they're always a random per param value
      ceilometer_metering           = { :string => '<%= @host.deployment.passwords.ceilometer_metering_secret %>' }
      heat_auth_encrypt_key         = { :string => '<%= @host.deployment.passwords.heat_auth_encrypt_key %>' }
      horizon_secret_key            = { :string => '<%= @host.deployment.passwords.horizon_secret_key %>' }
      swift_shared_secret           = { :string => '<%= @host.deployment.passwords.swift_shared_secret %>' }
      neutron_metadata_proxy_secret = { :string => '<%= @host.deployment.passwords.neutron_metadata_proxy_secret %>' }


      private_ip   = { :string => "<%= @host.deployment.network_query.ip_for_host(@host, '#{Staypuft::SubnetType::MANAGEMENT}') %>" }
      # private API/management
      amqp_host    = get_host_format :amqp_vip, Staypuft::SubnetType::MANAGEMENT
      mysql_host   = get_host_format :db_vip, Staypuft::SubnetType::MANAGEMENT
      glance_host  = get_host_format :glance_private_vip, Staypuft::SubnetType::MANAGEMENT
      neutron_host = get_host_format :neutron_private_vip, Staypuft::SubnetType::MANAGEMENT
      #admin API
      auth_host    = get_host_format :keystone_admin_vip, Staypuft::SubnetType::ADMIN_API
      # public API
      nova_host    = get_host_format :nova_public_vip, Staypuft::SubnetType::PUBLIC_API

      controller_admin_host = { :string => "<%= d = @host.deployment; d.ha? ? nil : d.network_query.controller_ip('#{Staypuft::SubnetType::ADMIN_API}') %>"}
      controller_priv_host  = { :string => "<%= d = @host.deployment; d.ha? ? nil : d.network_query.controller_ip('#{Staypuft::SubnetType::MANAGEMENT}') %>"}
      controller_pub_host   = { :string => "<%= d = @host.deployment; d.ha? ? nil : d.network_query.controller_ip('#{Staypuft::SubnetType::PUBLIC_API}') %>"}

      {
          'quickstack::nova_network::controller'   => {
              'amqp_provider'                           => amqp_provider,
              'cinder_backend_gluster'                  => cinder_backend_gluster,
              'cinder_backend_gluster_name'             => cinder_backend_gluster_name,
              'cinder_backend_iscsi'                    => cinder_backend_iscsi,
              'cinder_backend_iscsi_name'               => cinder_backend_iscsi_name,
              'cinder_backend_nfs'                      => cinder_backend_nfs,
              'cinder_backend_nfs_name'                 => cinder_backend_nfs_name,
              'cinder_backend_rbd'                      => cinder_backend_rbd,
              'cinder_backend_rbd_name'                 => cinder_backend_rbd_name,
              'cinder_backend_eqlx'                     => cinder_backend_eqlx,
              'cinder_backend_eqlx_name'                => cinder_backend_eqlx_name,
              'cinder_multiple_backends'                => cinder_multiple_backends,
              'cinder_nfs_shares'                       => cinder_nfs_shares,
              'cinder_nfs_mount_options'                => cinder_nfs_mount_options,
              'cinder_rbd_pool'                         => cinder_rbd_pool,
              'cinder_rbd_ceph_conf'                    => cinder_rbd_ceph_conf,
              'cinder_rbd_flatten_volume_from_snapshot' => cinder_rbd_flatten_volume_from_snapshot,
              'cinder_rbd_max_clone_depth'              => cinder_rbd_max_clone_depth,
              'cinder_rbd_user'                         => cinder_rbd_user,
              'cinder_rbd_secret_uuid'                  => cinder_rbd_secret_uuid,
              'cinder_san_ip'                           => cinder_san_ip,
              'cinder_san_login'                        => cinder_san_login,
              'cinder_san_password'                     => cinder_san_password,
              'cinder_san_thin_provision'               => cinder_san_thin_provision,
              'cinder_eqlx_group_name'                  => cinder_eqlx_group_name,
              'cinder_eqlx_pool'                        => cinder_eqlx_pool,
              'cinder_eqlx_use_chap'                    => cinder_eqlx_use_chap,
              'cinder_eqlx_chap_login'                  => cinder_eqlx_chap_login,
              'cinder_eqlx_chap_password'               => cinder_eqlx_chap_password,
              'glance_backend'                          => backend,
              'glance_rbd_store_user'                   => glance_rbd_store_user,
              'glance_rbd_store_pool'                   => glance_rbd_store_pool,
              'keystonerc'                              => keystonerc,
              'admin_password'                          => admin_pw,
              'ceilometer_user_password'                => ceilometer_user_pw,
              'cinder_db_password'                      => cinder_db_pw,
              'cinder_user_password'                    => cinder_user_pw,
              'glance_db_password'                      => glance_db_pw,
              'glance_user_password'                    => glance_user_pw,
              'heat_db_password'                        => heat_db_pw,
              'heat_user_password'                      => heat_user_pw,
              'keystone_db_password'                    => keystone_db_pw,
              'mysql_root_password'                     => mysql_root_pw,
              'nova_db_password'                        => nova_db_pw,
              'nova_user_password'                      => nova_user_pw,
              'swift_admin_password'                    => swift_admin_pw,
              'amqp_password'                           => amqp_pw,
              'amqp_nssdb_password'                     => amqp_nssdb_pw,
              'keystone_admin_token'                    => keystone_admin_token,
              'ceilometer_metering_secret'              => ceilometer_metering,
              'heat_auth_encrypt_key'                   => heat_auth_encrypt_key,
              'horizon_secret_key'                      => horizon_secret_key,
              'amqp_host'                               => amqp_host,
              'mysql_host'                              => mysql_host,
              'swift_shared_secret'                     => swift_shared_secret,
              'swift_ringserver_ip'                     => '',
              'swift_storage_ips'                       => { :array => "<%= @host.deployment.network_query.controller_ips('#{Staypuft::SubnetType::MANAGEMENT}') %>" },
              'cinder_gluster_shares'                   => [],
              'controller_admin_host'                   => controller_admin_host,
              'controller_priv_host'                    => controller_priv_host,
              'controller_pub_host'                     => controller_pub_host },
          'quickstack::neutron::controller'        => {
              'amqp_provider'                           => amqp_provider,
              'tenant_network_type'                     => tenant_network_type,
              'ml2_network_vlan_ranges'                 => ml2_network_vlan_ranges,
              'ml2_tenant_network_types'                => ml2_tenant_network_types,
              'ml2_tunnel_id_ranges'                    => ml2_tunnel_id_ranges,
              'ml2_vni_ranges'                          => ml2_vni_ranges,
              'ovs_vlan_ranges'                         => ovs_vlan_ranges,
              'enable_tunneling'                        => enable_tunneling,
              'cinder_backend_gluster'                  => cinder_backend_gluster,
              'cinder_backend_gluster_name'             => cinder_backend_gluster_name,
              'cinder_backend_iscsi'                    => cinder_backend_iscsi,
              'cinder_backend_iscsi_name'               => cinder_backend_iscsi_name,
              'cinder_backend_nfs'                      => cinder_backend_nfs,
              'cinder_backend_nfs_name'                 => cinder_backend_nfs_name,
              'cinder_backend_rbd'                      => cinder_backend_rbd,
              'cinder_backend_rbd_name'                 => cinder_backend_rbd_name,
              'cinder_backend_eqlx'                     => cinder_backend_eqlx,
              'cinder_backend_eqlx_name'                => cinder_backend_eqlx_name,
              'cinder_multiple_backends'                => cinder_multiple_backends,
              'cinder_nfs_shares'                       => cinder_nfs_shares,
              'cinder_nfs_mount_options'                => cinder_nfs_mount_options,
              'cinder_rbd_pool'                         => cinder_rbd_pool,
              'cinder_rbd_ceph_conf'                    => cinder_rbd_ceph_conf,
              'cinder_rbd_flatten_volume_from_snapshot' => cinder_rbd_flatten_volume_from_snapshot,
              'cinder_rbd_max_clone_depth'              => cinder_rbd_max_clone_depth,
              'cinder_rbd_user'                         => cinder_rbd_user,
              'cinder_rbd_secret_uuid'                  => cinder_rbd_secret_uuid,
              'cinder_san_ip'                           => cinder_san_ip,
              'cinder_san_login'                        => cinder_san_login,
              'cinder_san_password'                     => cinder_san_password,
              'cinder_san_thin_provision'               => cinder_san_thin_provision,
              'cinder_eqlx_group_name'                  => cinder_eqlx_group_name,
              'cinder_eqlx_pool'                        => cinder_eqlx_pool,
              'cinder_eqlx_use_chap'                    => cinder_eqlx_use_chap,
              'cinder_eqlx_chap_login'                  => cinder_eqlx_chap_login,
              'cinder_eqlx_chap_password'               => cinder_eqlx_chap_password,
              'glance_backend'                          => backend,
              'glance_rbd_store_user'                   => glance_rbd_store_user,
              'glance_rbd_store_pool'                   => glance_rbd_store_pool,
              'keystonerc'                              => keystonerc,
              'admin_password'                          => admin_pw,
              'ceilometer_user_password'                => ceilometer_user_pw,
              'cinder_db_password'                      => cinder_db_pw,
              'cinder_user_password'                    => cinder_user_pw,
              'glance_db_password'                      => glance_db_pw,
              'glance_user_password'                    => glance_user_pw,
              'heat_db_password'                        => heat_db_pw,
              'heat_user_password'                      => heat_user_pw,
              'keystone_db_password'                    => keystone_db_pw,
              'mysql_root_password'                     => mysql_root_pw,
              'neutron_db_password'                     => neutron_db_pw,
              'neutron_user_password'                   => neutron_user_pw,
              'nova_db_password'                        => nova_db_pw,
              'nova_user_password'                      => nova_user_pw,
              'swift_admin_password'                    => swift_admin_pw,
              'amqp_password'                           => amqp_pw,
              'amqp_nssdb_password'                     => amqp_nssdb_pw,
              'keystone_admin_token'                    => keystone_admin_token,
              'ceilometer_metering_secret'              => ceilometer_metering,
              'heat_auth_encrypt_key'                   => heat_auth_encrypt_key,
              'horizon_secret_key'                      => horizon_secret_key,
              'swift_shared_secret'                     => swift_shared_secret,
              'neutron_metadata_proxy_secret'           => neutron_metadata_proxy_secret,
              'amqp_host'                               => amqp_host,
              'mysql_host'                              => mysql_host,
              'swift_shared_secret'                     => swift_shared_secret,
              'swift_ringserver_ip'                     => '',
              'swift_storage_ips'                       => { :array => "<%= @host.deployment.network_query.controller_ips('#{Staypuft::SubnetType::MANAGEMENT}') %>" },
              'cinder_gluster_shares'                   => [],
              'controller_admin_host'                   => controller_admin_host,
              'controller_priv_host'                    => controller_priv_host,
              'controller_pub_host'                     => controller_pub_host },
          'quickstack::pacemaker::params'          => {
              'include_swift'                 => 'false',
              'include_neutron'               => neutron,
              'neutron'                       => neutron,
              'ceilometer_user_password'      => ceilometer_user_pw,
              'cinder_db_password'            => cinder_db_pw,
              'cinder_user_password'          => cinder_user_pw,
              'glance_db_password'            => glance_db_pw,
              'glance_user_password'          => glance_user_pw,
              'heat_db_password'              => heat_db_pw,
              'heat_user_password'            => heat_user_pw,
              'heat_cfn_user_password'        => heat_cfn_user_pw,
              'keystone_db_password'          => keystone_db_pw,
              'keystone_user_password'        => keystone_user_pw,
              'neutron_db_password'           => neutron_db_pw,
              'neutron_user_password'         => neutron_user_pw,
              'nova_db_password'              => nova_db_pw,
              'nova_user_password'            => nova_user_pw,
              'amqp_provider'                 => amqp_provider,
              'amqp_password'                 => amqp_pw,
              'heat_auth_encryption_key'      => heat_auth_encrypt_key,
              'neutron_metadata_proxy_secret' => neutron_metadata_proxy_secret,
              'ceilometer_admin_vip'          => vip_format(:ceilometer_admin_vip),
              'ceilometer_private_vip'        => vip_format(:ceilometer_private_vip),
              'ceilometer_public_vip'         => vip_format(:ceilometer_public_vip),
              'cinder_admin_vip'              => vip_format(:cinder_admin_vip),
              'cinder_private_vip'            => vip_format(:cinder_private_vip),
              'cinder_public_vip'             => vip_format(:cinder_public_vip),
              'db_vip'                        => vip_format(:db_vip),
              'glance_admin_vip'              => vip_format(:glance_admin_vip),
              'glance_private_vip'            => vip_format(:glance_private_vip),
              'glance_public_vip'             => vip_format(:glance_public_vip),
              'heat_admin_vip'                => vip_format(:heat_admin_vip),
              'heat_private_vip'              => vip_format(:heat_private_vip),
              'heat_public_vip'               => vip_format(:heat_public_vip),
              'heat_cfn_admin_vip'            => vip_format(:heat_cfn_admin_vip),
              'heat_cfn_private_vip'          => vip_format(:heat_cfn_private_vip),
              'heat_cfn_public_vip'           => vip_format(:heat_cfn_public_vip),
              'horizon_admin_vip'             => vip_format(:horizon_admin_vip),
              'horizon_private_vip'           => vip_format(:horizon_private_vip),
              'horizon_public_vip'            => vip_format(:horizon_public_vip),
              'keystone_admin_vip'            => vip_format(:keystone_admin_vip),
              'keystone_private_vip'          => vip_format(:keystone_private_vip),
              'keystone_public_vip'           => vip_format(:keystone_public_vip),
              'loadbalancer_vip'              => vip_format(:loadbalancer_vip),
              'neutron_admin_vip'             => vip_format(:neutron_admin_vip),
              'neutron_private_vip'           => vip_format(:neutron_private_vip),
              'neutron_public_vip'            => vip_format(:neutron_public_vip),
              'nova_admin_vip'                => vip_format(:nova_admin_vip),
              'nova_private_vip'              => vip_format(:nova_private_vip),
              'nova_public_vip'               => vip_format(:nova_public_vip),
              'amqp_vip'                      => vip_format(:amqp_vip),
              'swift_public_vip'              => vip_format(:swift_public_vip),
              'private_ip'                    => private_ip,
              'cluster_control_ip'            => { :string => "<%= @host.deployment.network_query.controller_ips('#{Staypuft::SubnetType::MANAGEMENT}').first %>" },
              'lb_backend_server_addrs'       => { :array => "<%= @host.deployment.network_query.controller_ips('#{Staypuft::SubnetType::MANAGEMENT}') %>" },
              'lb_backend_server_names'       => { :array => '<%= @host.deployment.network_query.controller_fqdns %>' } },
          'quickstack::pacemaker::common'          => {
              'pacemaker_cluster_members' => { :string => "<%= @host.deployment.network_query.controller_ips('#{Staypuft::SubnetType::MANAGEMENT}').join(' ') %>" } },
          'quickstack::pacemaker::neutron'         => {
              'ml2_network_vlan_ranges'  => ml2_network_vlan_ranges,
              'ml2_tenant_network_types' => ml2_tenant_network_types,
              'ml2_tunnel_id_ranges'     => ml2_tunnel_id_ranges,
              'enable_tunneling'         => enable_tunneling,
              'ovs_bridge_mappings'      => ovs_bridge_mappings,
              'ovs_bridge_uplinks'       => ovs_bridge_uplinks,
              'ovs_tunnel_iface'         => ovs_tunnel_iface,
              'ovs_tunnel_types'         => ovs_tunnel_types,
              'ovs_vlan_ranges'          => ovs_vlan_ranges },
          'quickstack::pacemaker::glance'          => {
              'backend'         => backend,
              'pcmk_fs_type'    => pcmk_fs_type,
              'pcmk_fs_device'  => pcmk_fs_device,
              'pcmk_fs_dir'     => pcmk_fs_dir,
              'pcmk_fs_manage'  => pcmk_fs_manage,
              'pcmk_fs_options' => pcmk_fs_options },
          'quickstack::pacemaker::cinder'          => {
              'volume'                           => volume,
              'backend_iscsi'                    => cinder_backend_iscsi,
              'backend_nfs'                      => cinder_backend_nfs,
              'backend_gluster'                  => cinder_backend_gluster,
              'nfs_shares'                       => cinder_nfs_shares,
              'nfs_mount_options'                => cinder_nfs_mount_options,
              'backend_rbd'                      => cinder_backend_rbd,
              'rbd_pool'                         => cinder_rbd_pool,
              'rbd_ceph_conf'                    => cinder_rbd_ceph_conf,
              'rbd_flatten_volume_from_snapshot' => cinder_rbd_flatten_volume_from_snapshot,
              'rbd_max_clone_depth'              => cinder_rbd_max_clone_depth,
              'rbd_user'                         => cinder_rbd_user,
              'rbd_secret_uuid'                  => cinder_rbd_secret_uuid,
              'backend_eqlx'                     => cinder_backend_eqlx,
              'san_ip'                           => cinder_san_ip,
              'san_login'                        => cinder_san_login,
              'san_password'                     => cinder_san_password,
              'san_thin_provision'               => cinder_san_thin_provision,
              'eqlx_group_name'                  => cinder_eqlx_group_name,
              'eqlx_pool'                        => cinder_eqlx_pool,
              'eqlx_use_chap'                    => cinder_eqlx_use_chap,
              'eqlx_chap_login'                  => cinder_eqlx_chap_login,
              'eqlx_chap_password'               => cinder_eqlx_chap_password },
          'quickstack::pacemaker::keystone'        => {
              'keystonerc'     => keystonerc,
              'admin_password' => admin_pw,
              'admin_token'    => keystone_admin_token },
          'quickstack::pacemaker::horizon'         => {
              'secret_key' => horizon_secret_key },
          'quickstack::pacemaker::galera'          => {
              'mysql_root_password'   => mysql_root_pw,
              'wsrep_cluster_members' => { :array => "<%= @host.deployment.network_query.controller_ips('#{Staypuft::SubnetType::MANAGEMENT}') %>" } },
          'quickstack::pacemaker::swift'           => {
              'swift_shared_secret' => swift_shared_secret,
              'swift_storage_ips'   => [] },
          'quickstack::pacemaker::nova'            => {
              'multi_host'                    => 'true',
              'neutron_metadata_proxy_secret' => neutron_metadata_proxy_secret },
          'quickstack::neutron::networker'         => {
              'amqp_provider'                 => amqp_provider,
              'enable_tunneling'              => enable_tunneling,
              'tenant_network_type'           => tenant_network_type,
              'ovs_bridge_mappings'           => ovs_bridge_mappings,
              'ovs_bridge_uplinks'            => ovs_bridge_uplinks,
              'ovs_tunnel_iface'              => ovs_tunnel_iface,
              'ovs_tunnel_types'              => ovs_tunnel_types,
              'ovs_vlan_ranges'               => ovs_vlan_ranges,
              'neutron_db_password'           => neutron_db_pw,
              'neutron_user_password'         => neutron_user_pw,
              'nova_db_password'              => nova_db_pw,
              'nova_user_password'            => nova_user_pw,
              'amqp_password'                 => amqp_pw,
              'neutron_metadata_proxy_secret' => neutron_metadata_proxy_secret,
              'amqp_host'                     => amqp_host,
              'mysql_host'                    => mysql_host,
              'controller_priv_host'          => controller_priv_host },
          'quickstack::storage_backend::cinder'    => {
              'amqp_provider'        => amqp_provider,
              'cinder_db_password'   => cinder_db_pw,
              'cinder_user_password' => cinder_user_pw,
              'amqp_password'        => amqp_pw },
          'quickstack::nova_network::compute'      => {
              'amqp_provider'              => amqp_provider,
              'ceilometer'                 => ceilometer,
              'cinder_backend_gluster'     => cinder_backend_gluster,
              'cinder_backend_nfs'         => cinder_backend_nfs,
              'cinder_backend_rbd'         => cinder_backend_rbd,
              'rbd_secret_uuid'            => cinder_rbd_secret_uuid,
              'network_manager'            => network_manager,
              'network_overrides'          => network_overrides,
              'network_num_networks'       => network_num_networks,
              'network_fixed_range'        => network_fixed_range,
              'network_floating_range'     => network_floating_range,
              'network_private_iface'      => network_private_iface,
              'network_public_iface'       => network_public_iface,
              'network_create_networks'    => network_create_networks,
              'nova_multi_host'            => 'true',
              'admin_password'             => admin_pw,
              'ceilometer_user_password'   => ceilometer_user_pw,
              'nova_db_password'           => nova_db_pw,
              'nova_user_password'         => nova_user_pw,
              'amqp_password'              => amqp_pw,
              'ceilometer_metering_secret' => ceilometer_metering,
              'amqp_host'                  => amqp_host,
              'mysql_host'                 => mysql_host,
              'glance_host'                => glance_host,
              'auth_host'                  => auth_host,
              'nova_host'                  => nova_host,
              'private_ip'                 => private_ip },
          'quickstack::neutron::compute'           => {
              'amqp_provider'              => amqp_provider,
              'ceilometer'                 => ceilometer,
              'cinder_backend_gluster'     => cinder_backend_gluster,
              'cinder_backend_nfs'         => cinder_backend_nfs,
              'cinder_backend_rbd'         => cinder_backend_rbd,
              'rbd_secret_uuid'            => cinder_rbd_secret_uuid,
              'enable_tunneling'           => enable_tunneling,
              'tenant_network_type'        => tenant_network_type,
              'ovs_bridge_mappings'        => compute_ovs_bridge_mappings,
              'ovs_bridge_uplinks'         => compute_ovs_bridge_uplinks,
              'ovs_tunnel_iface'           => compute_ovs_tunnel_iface,
              'ovs_tunnel_types'           => ovs_tunnel_types,
              'ovs_vlan_ranges'            => compute_ovs_vlan_ranges,
              'admin_password'             => admin_pw,
              'ceilometer_user_password'   => ceilometer_user_pw,
              'neutron_db_password'        => neutron_db_pw,
              'neutron_user_password'      => neutron_user_pw,
              'nova_db_password'           => nova_db_pw,
              'nova_user_password'         => nova_user_pw,
              'amqp_password'              => amqp_pw,
              'ceilometer_metering_secret' => ceilometer_metering,
              'amqp_host'                  => amqp_host,
              'mysql_host'                 => mysql_host,
              'glance_host'                => glance_host,
              'auth_host'                  => auth_host,
              'neutron_host'               => neutron_host,
              'nova_host'                  => nova_host,
              'private_ip'                 => private_ip },
          'quickstack::pacemaker::rsync::keystone' => {
              'keystone_private_vip' => vip_format(:keystone) } }
    end

    def get_key_type_and_value(value)
      key_list   = LookupKey::KEY_TYPES
      if value.class == Hash
        key_type = value.keys.first.to_s
        key_value = value.values.first
      else
        key_value = value
        value_type = value.class.to_s.downcase
        if key_list.include?(value_type)
          key_type = value_type
        elsif [FalseClass, TrueClass].include? value.class
          key_type = 'boolean'
        else
          raise
        end
      end
      # If we need to handle actual number classes like Fixnum, add those here
      [key_type, key_value]
    end

    def seed_layouts
      LAYOUTS.each do |key, layout_hash|
        LAYOUTS[key][:obj] = Staypuft::Layout.where(layout_hash).first_or_create!
      end
    end

    def seed_services
      SERVICES.each do |key, service_hash|
        service = Staypuft::Service.where(:name => service_hash[:name]).first_or_create!

        puppet_classes = collect_puppet_classes(Array(service_hash[:class]))
        puppet_classes.each { |pc| apply_astapor_defaults pc }
        service.puppetclasses = puppet_classes

        service.description = service_hash[:description]
        service.save!
        service_hash[:obj] = service
      end
    end

    def seed_roles
      ROLES.each do |role_hash|
        role = Staypuft::Role.where(:name => role_hash[:name]).first_or_initialize

        puppet_classes = collect_puppet_classes(Array(role_hash[:class]))
        puppet_classes.each { |pc| apply_astapor_defaults pc }
        role.puppetclasses = puppet_classes

        role.description      = role_hash[:description]
        role.orchestration    = role_hash[:orchestration]
        role.save!
        old_role_services_arr = role.role_services.to_a
        role_hash[:services].each do |key|
          role_service = role.role_services.where(:service_id => SERVICES[key][:obj].id).first_or_create!
          old_role_services_arr.delete(role_service)
        end

        # delete any prior mappings that remain
        old_role_services_arr.each do |role_service|
          role.services.destroy(role_service.service)
        end
        role.save!
        old_layout_roles_arr = role.layout_roles.to_a
        role_hash[:layouts].each do |layout, deploy_order|
          layout_role              = role.layout_roles.where(:layout_id => LAYOUTS[layout][:obj].id).first_or_initialize
          layout_role.deploy_order = deploy_order
          layout_role.save!
          old_layout_roles_arr.delete(layout_role)
        end
        # delete any prior mappings that remain
        old_layout_roles_arr.each do |layout_role|
          role.layouts.destroy(layout_role.layout)
        end
      end
    end

    def seed_functional_dependencies
      functional_dependencies.each do |puppetclass_name, params|
        puppetclass = Puppetclass.find_by_name(puppetclass_name)
        unless puppetclass
          Rails.logger.error "missing puppet class #{puppetclass_name}"
          next
        end
        params.each do |param_key, default_value|
          param = puppetclass.class_params.find_by_key(param_key)
          unless param
            Rails.logger.error "missing param #{param_key} in #{puppetclass_name} trying to set default_value: #{default_value.inspect} found in puppetclasses: " +
                                   LookupKey.
                                       smart_class_parameters.
                                       search_for("key = #{param_key}").
                                       map { |lk| lk.param_class.name }.inspect
            next
          end
          param_type, param_value = get_key_type_and_value(default_value)
          unless param.update_attributes key_type: param_type, default_value: param_value
            Rails.logger.error "param #{param_key} in #{puppetclass_name} default_value: #{param_value.inspect} is invalid"
          end
        end
      end
    end

    def seed_subnet_types
      # default subnet types
      SUBNET_TYPES.each do |key, subnet_type_hash|
        subnet_type = Staypuft::SubnetType.where(:name => subnet_type_hash[:name]).first_or_initialize
        subnet_type.is_required = subnet_type_hash[:required]
        subnet_type.save!
        old_layout_subnet_types_arr = subnet_type.layout_subnet_types.to_a
        subnet_type_hash[:layouts].each do |layout|
          layout_subnet_type              = subnet_type.layout_subnet_types.where(:layout_id => LAYOUTS[layout][:obj].id).first_or_create!
          old_layout_subnet_types_arr.delete(layout_subnet_type)
        end
        # delete any prior mappings that remain
        old_layout_subnet_types_arr.each do |layout_subnet_type|
          Rails.logger.warn "destroying old layout_subnet_type for #{layout_subnet_type.layout.name}, #{subnet_type.name}: This should not happen on a clean install"
          subnet_type.layouts.destroy(layout_subnet_type.layout)
        end
      end
    end

    def seed
      seed_layouts
      seed_services
      seed_roles
      seed_functional_dependencies
      seed_subnet_types
    end

    def collect_puppet_classes(puppet_class_names)
      puppet_class_names.map do |puppet_class_name|
        Puppetclass.find_by_name(puppet_class_name).tap do |v|
          Rails.logger.warn "no puppet_class: #{puppet_class_name} found" unless v
        end
      end.compact
    end

    def apply_astapor_defaults(puppet_class)
      puppet_class.class_params.each do |param|
        if ASTAPOR_PARAMS.include?(param.key)
          param.key_type, param.default_value = get_key_type_and_value(ASTAPOR_PARAMS[param.key])
        end
        param.override = true
        param.save!
      end
      puppet_class
    end
  end
end

# require 'set'
# applied_params = Set.new
#
# not_applied_params = ASTAPOR_PARAMS.keys - applied_params.to_a
# unless not_applied_params.empty?
#   Rails.logger.error "following params were not applied: #{not_applied_params.inspect}"
# end
