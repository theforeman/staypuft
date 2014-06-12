# Libs
require 'facter'
require 'securerandom'

# enabling puppet run'
#Setting['puppetrun'] = true

# FIXME: this is the list pulled as-is from astapor. Any changes for staypuft are not
# yet in place. In addition, I don't know if we want to break these down by
# Role, or leave them in one big list (internally they get set per puppetclass)
params = {
    'verbose'                       => 'true',
    'heat_cfn'                      => 'false',
    'heat_cloudwatch'               => 'false',
    'admin_password'                => SecureRandom.hex,
    'ceilometer'                    => 'true',
    'ceilometer_host'               => 'false',
    'ceilometer_metering_secret'    => SecureRandom.hex,
    'ceilometer_user_password'      => SecureRandom.hex,
    'cinder_db_password'            => SecureRandom.hex,
    'cinder_user_password'          => SecureRandom.hex,
    'cinder_backend_gluster'        => 'false',
    'cinder_backend_iscsi'          => 'false',
    'cinder_gluster_peers'          => [],
    'cinder_gluster_volume'         => 'cinder',
    'cinder_gluster_replica_count'  => '3',
    'cinder_gluster_servers'        => %w(192.168.0.4 192.168.0.5 192.168.0.6),
    'glance_db_password'            => SecureRandom.hex,
    'glance_user_password'          => SecureRandom.hex,
    'glance_gluster_peers'          => [],
    'glance_gluster_volume'         => 'glance',
    'glance_gluster_replica_count'  => '3',
    'gluster_open_port_count'       => '10',
    'heat_db_password'              => SecureRandom.hex,
    'heat_user_password'            => SecureRandom.hex,
    'heat_cfn_user_password'        => SecureRandom.hex,
    'heat_auth_encrypt_key'         => SecureRandom.hex,
    'horizon_secret_key'            => SecureRandom.hex,
    'keystone_admin_token'          => SecureRandom.hex,
    'keystone_db_password'          => SecureRandom.hex,
    'keystone_user_password'        => SecureRandom.hex,
    'mysql_root_password'           => SecureRandom.hex,
    'neutron_db_password'           => SecureRandom.hex,
    'neutron_user_password'         => SecureRandom.hex,
    'nova_db_password'              => SecureRandom.hex,
    'nova_user_password'            => SecureRandom.hex,
    'nova_default_floating_pool'    => 'nova',
    'swift_admin_password'          => SecureRandom.hex,
    'swift_shared_secret'           => SecureRandom.hex,
    'swift_user_password'           => SecureRandom.hex,
    'swift_all_ips'                 => %w(192.168.203.1 192.168.203.2 192.168.203.3 192.168.203.4),
    'swift_ext4_device'             => '/dev/sdc2',
    'swift_local_interface'         => 'eth3',
    'swift_loopback'                => true,
    'swift_ring_server'             => '192.168.203.1',
    'fixed_network_range'           => '10.0.0.0/24',
    'floating_network_range'        => '10.0.1.0/24',
    'controller_admin_host'         => '172.16.0.1',
    'controller_priv_host'          => '172.16.0.1',
    'controller_pub_host'           => '172.16.1.1',
    'mysql_host'                    => '172.16.0.1',
    'mysql_virtual_ip'              => '192.168.200.220',
    'mysql_bind_address'            => '0.0.0.0',
    'mysql_virt_ip_nic'             => 'eth1',
    'mysql_virt_ip_cidr_mask'       => '24',
    'mysql_shared_storage_device'   => '192.168.203.200:/mnt/mysql',
    'mysql_shared_storage_type'     => 'nfs',
    'mysql_resource_group_name'     => 'mysqlgrp',
    'mysql_clu_member_addrs'        => '192.168.203.11 192.168.203.12 192.168.203.13',
    "amqp_server"                   => 'rabbitmq',
    'amqp_host'                     => '172.16.0.1',
    'amqp_username'                 => 'openstack',
    'amqp_password'                 => SecureRandom.hex,
    'admin_email'                   => "admin@#{Facter.value(:domain)}",
    'neutron_metadata_proxy_secret' => SecureRandom.hex,
    'enable_ovs_agent'              => 'true',
    'ovs_vlan_ranges'               => '',
    'ovs_bridge_mappings'           => [],
    'ovs_bridge_uplinks'            => [],
    'ovs_tunnel_iface'              => 'eth0',
    'tenant_network_type'           => 'vxlan',
    'enable_tunneling'              => 'True',
    'ovs_vxlan_udp_port'            => '4789',
    'ovs_tunnel_types'              => ['vxlan'],
    'auto_assign_floating_ip'       => 'True',
    'cisco_vswitch_plugin'          => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
    'cisco_nexus_plugin'            => 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin',
    'nexus_config'                  => {},
    'nexus_credentials'             => [],
    'provider_vlan_auto_create'     => 'false',
    'provider_vlan_auto_trunk'      => 'false',
    'backend_server_names'          => [],
    'backend_server_addrs'          => [],
    'lb_backend_server_names'       => [],
    'lb_backend_server_addrs'       => [],
    'configure_ovswitch'            => 'true',
    'neutron'                       => 'false',
    'ssl'                           => 'false',
    'freeipa'                       => 'false',
    'mysql_ca'                      => '/etc/ipa/ca.crt',
    'mysql_cert'                    => '/etc/pki/tls/certs/PRIV_HOST-mysql.crt',
    'mysql_key'                     => '/etc/pki/tls/private/PRIV_HOST-mysql.key',
    'amqp_ca'                       => '/etc/ipa/ca.crt',
    'amqp_cert'                     => '/etc/pki/tls/certs/PRIV_HOST-amqp.crt',
    'amqp_key'                      => '/etc/pki/tls/private/PRIV_HOST-amqp.key',
    'horizon_ca'                    => '/etc/ipa/ca.crt',
    'horizon_cert'                  => '/etc/pki/tls/certs/PUB_HOST-horizon.crt',
    'horizon_key'                   => '/etc/pki/tls/private/PUB_HOST-horizon.key',
    'amqp_nssdb_password'           => SecureRandom.hex,
    'fence_xvm_key_file_password'   => SecureRandom.hex,
    'use_qemu_for_poc'              => 'false',
    'secret_key'                    => SecureRandom.hex,
    'admin_token'                   => SecureRandom.hex,
}

get_key_type = lambda do |value|
  key_list   = LookupKey::KEY_TYPES
  value_type = value.class.to_s.downcase
  if key_list.include?(value_type)
    value_type
  elsif [FalseClass, TrueClass].include? value.class
    'boolean'
  end
  # If we need to handle actual number classes like Fixnum, add those here
end


# key (:ha, etc) is only  used internally for referencing from roles
layouts      = {
    :ha_nova        => Staypuft::Layout.where(:name       => 'Distributed with High Availability',
                                              :networking => 'nova').first_or_create!,
    :non_ha_nova    => Staypuft::Layout.where(:name       => 'Distributed',
                                              :networking => 'nova').first_or_create!,
    :ha_neutron     => Staypuft::Layout.where(:name       => 'Distributed with High Availability',
                                              :networking => 'neutron').first_or_create!,
    :non_ha_neutron => Staypuft::Layout.where(:name       => 'Distributed',
                                              :networking => 'neutron').first_or_create!,
}

# services don't have puppetclasses yet, since they aren't broken out on the back end
services     = {
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
    :mysql_ha           => { :name => 'Mysql (HA)', :class => ['quickstack::pacemaker::mysql'] },
    :neutron_ha         => { :name => 'Neutron (HA)', :class => ['quickstack::pacemaker::neutron'] }
}
services.each do |key, service_hash|
  service               = Staypuft::Service.where(:name => service_hash[:name]).first_or_create!

  # set params in puppetclass
  puppet_class_names    = service_hash[:class].kind_of?(Array) ? service_hash[:class] : [service_hash[:class]]
  service.puppetclasses = puppet_class_names.collect do |puppet_class_name|
    puppet_class = Puppetclass.find_by_name puppet_class_name
    # skip if puppet class isn't found (yet)
    if puppet_class
      puppet_class.class_params.each do |p|
        if params.include?(p.key)
          p.key_type      = get_key_type.(params[p.key])
          p.default_value = params[p.key]
        end
        p.override = true
        p.save!
      end
      puppet_class
    end
  end.compact

  service.description = service_hash[:description]
  service.save!
  service_hash[:obj] = service
end

# The list of roles is still from astapor
# FIXME for now layouts are different based on Nova vs. Neutron networks. This is
#  actually incorrect, but it's a placeholder example of how layouts might differ
# until we get the real list of roles per layout
# layout refs below specify layout keys from layouts hash
roles = [
    { :name     => 'Controller (Nova)',
      :class    => 'quickstack::nova_network::controller',
      :layouts  => [[:non_ha_nova, 1]],
      :services => [:non_ha_amqp, :mysql, :non_ha_keystone, :nova_controller, :non_ha_glance,
                    :cinder_controller, :heat, :ceilometer] },
    { :name     => 'Compute (Nova)',
      :class    => [],
      :layouts  => [[:ha_nova, 10], [:non_ha_nova, 10]],
      :services => [:nova_compute] },
    { :name     => 'Controller (Neutron)',
      :class    => 'quickstack::neutron::controller',
      :layouts  => [[:non_ha_neutron, 1]],
      :services => [:non_ha_amqp, :mysql, :non_ha_keystone, :neutron_controller, :non_ha_glance,
                    :cinder_controller, :heat, :ceilometer] },
    { :name     => 'Compute (Neutron)',
      :class    => [],
      :layouts  => [[:ha_neutron, 10], [:non_ha_neutron, 10]],
      :services => [:neutron_compute] },
    { :name     => 'Neutron Networker',
      :class    => [],
      :layouts  => [[:non_ha_neutron, 3]],
      :services => [:neutron_networker] },
    { :name     => 'Cinder Block Storage',
      :class    => [],
      :layouts  => [[:ha_nova, 2], [:ha_neutron, 2], [:non_ha_nova, 2], [:non_ha_neutron, 2]],
      :services => [:cinder_node] },
    { :name     => 'Swift Storage Node',
      :class    => [],
      :layouts  => [[:ha_nova, 5], [:ha_neutron, 5], [:non_ha_nova, 5], [:non_ha_neutron, 5]],
      :services => [:swift] },
    { :name     => 'HA Controller',
      :class    => [],
      :layouts  => [[:ha_nova, 1], [:ha_neutron, 1]],
      :services => [:ha_controller, :keystone_ha, :load_balancer_ha, :memcached_ha, :qpid_ha,
                    :glance_ha, :nova_ha, :heat_ha, :cinder_ha, :swift_ha, :horizon_ha, :mysql_ha,
                    :neutron_ha] }
]

roles.each do |role_hash|
  #create role
  role               = Staypuft::Role.where(:name => role_hash[:name]).first_or_create!

  # set params in puppetclass
  puppet_class_names = role_hash[:class].kind_of?(Array) ? role_hash[:class] : [role_hash[:class]]
  role.puppetclasses = puppet_class_names.collect do |puppet_class_name|
    puppet_class = Puppetclass.find_by_name puppet_class_name

    # skip if puppet class isn't found (yet)
    if puppet_class
      puppet_class.class_params.each do |param|
        if params.include?(param.key)
          param.key_type      = get_key_type.(params[param.key])
          param.default_value = params[param.key]
        end
        param.override = true
        param.save!
      end
      puppet_class
    else
      Rails.logger.warn "no puppet_class: #{puppet_class_name} found"
      nil
    end
  end.compact

  role.description      = role_hash[:description]
  old_role_services_arr = role.role_services.to_a
  role_hash[:services].each do |key|
    role_service = role.role_services.where(:service_id => services[key][:obj].id).first_or_create!
    old_role_services_arr.delete(role_service)
  end

  # delete any prior mappings that remain
  old_role_services_arr.each do |role_service|
    role.services.destroy(role_service.service)
  end
  role.save!
  old_layout_roles_arr = role.layout_roles.to_a
  role_hash[:layouts].each do |layout, deploy_order|
    layout_role              = role.layout_roles.where(:layout_id => layouts[layout].id).first_or_initialize
    layout_role.deploy_order = deploy_order
    layout_role.save!
    old_layout_roles_arr.delete(layout_role)
  end
  # delete any prior mappings that remain
  old_layout_roles_arr.each do |layout_role|
    role.layouts.destroy(layout_role.layout)
  end
end
