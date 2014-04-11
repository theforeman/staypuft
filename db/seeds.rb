# Libs
require 'facter'
require 'securerandom'

# enabling puppet run'
#Setting['puppetrun'] = true

# FIXME: this is the list pulled as-is from astapor. Any changes for staypuft are not
# yet in place. In addition, I don't know if we want to break these down by
# Role, or leave them in one big list (internally they get set per puppetclass)
params = {
  "verbose"                       => "true",
  "heat_cfn"                      => "false",
  "heat_cloudwatch"               => "false",
  "admin_password"                => SecureRandom.hex,
  "ceilometer_metering_secret"    => SecureRandom.hex,
  "ceilometer_user_password"      => SecureRandom.hex,
  "cinder_db_password"            => SecureRandom.hex,
  "cinder_user_password"          => SecureRandom.hex,
  "cinder_backend_gluster"        => "false",
  "cinder_backend_iscsi"          => "false",
  "cinder_gluster_peers"          => [],
  "cinder_gluster_volume"         => "cinder",
  "cinder_gluster_replica_count"  => '3',
  "cinder_gluster_servers"        => [ '192.168.0.4', '192.168.0.5', '192.168.0.6' ],
  "glance_db_password"            => SecureRandom.hex,
  "glance_user_password"          => SecureRandom.hex,
  "glance_gluster_peers"          => [],
  "glance_gluster_volume"         => "glance",
  "glance_gluster_replica_count"  => '3',
  "gluster_open_port_count"       => '10',
  "heat_db_password"              => SecureRandom.hex,
  "heat_user_password"            => SecureRandom.hex,
  "heat_cfn_user_password"        => SecureRandom.hex,
  "horizon_secret_key"            => SecureRandom.hex,
  "keystone_admin_token"          => SecureRandom.hex,
  "keystone_db_password"          => SecureRandom.hex,
  "keystone_user_password"        => SecureRandom.hex,
  "mysql_root_password"           => SecureRandom.hex,
  "neutron_db_password"           => SecureRandom.hex,
  "neutron_user_password"         => SecureRandom.hex,
  "nova_db_password"              => SecureRandom.hex,
  "nova_user_password"            => SecureRandom.hex,
  "nova_default_floating_pool"    => "nova",
  "swift_admin_password"          => SecureRandom.hex,
  "swift_shared_secret"           => SecureRandom.hex,
  "swift_user_password"           => SecureRandom.hex,
  "swift_all_ips"                 => ['192.168.203.1', '192.168.203.2', '192.168.203.3', '192.168.203.4'],
  "swift_ext4_device"             => '/dev/sdc2',
  "swift_local_interface"         => 'eth3',
  "swift_loopback"                => true,
  "swift_ring_server"             => '192.168.203.1',
  "fixed_network_range"           => '10.0.0.0/24',
  "floating_network_range"        => '10.0.1.0/24',
  "controller_admin_host"         => '172.16.0.1',
  "controller_priv_host"          => '172.16.0.1',
  "controller_pub_host"           => '172.16.1.1',
  "mysql_host"                    => '172.16.0.1',
  "mysql_virtual_ip"              => '192.168.200.220',
  "mysql_bind_address"            => '0.0.0.0',
  "mysql_virt_ip_nic"             => 'eth1',
  "mysql_virt_ip_cidr_mask"       =>  '24',
  "mysql_shared_storage_device"   => '192.168.203.200:/mnt/mysql',
  "mysql_shared_storage_type"     => 'nfs',
  "mysql_resource_group_name"     => 'mysqlgrp',
  "mysql_clu_member_addrs"        => '192.168.203.11 192.168.203.12 192.168.203.13',
  "qpid_host"                     => '172.16.0.1',
  "qpid_username"                 => 'openstack',
  "qpid_password"                 => SecureRandom.hex,
  "admin_email"                   => "admin@#{Facter.value(:domain)}",
  "neutron_metadata_proxy_secret" => SecureRandom.hex,
  "enable_ovs_agent"              => "true",
  "ovs_vlan_ranges"               => '',
  "ovs_bridge_mappings"           => [],
  "ovs_bridge_uplinks"            => [],
  "ovs_tunnel_iface"              => 'eth0',
  "tenant_network_type"           => 'gre',
  "enable_tunneling"              => 'True',
  "ovs_vxlan_udp_port"            => '4789',
  "ovs_tunnel_types"              => [],
  "auto_assign_floating_ip"       => 'True',
  "neutron_core_plugin"           => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
  "cisco_vswitch_plugin"          => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
  "cisco_nexus_plugin"            => 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin',
  "nexus_config"                  => {},
  "nexus_credentials"             => [],
  "provider_vlan_auto_create"     => "false",
  "provider_vlan_auto_trunk"      => "false",
  "backend_server_names"          => [],
  "backend_server_addrs"          => [],
  "lb_backend_server_names"       => [],
  "lb_backend_server_addrs"       => [],
  "configure_ovswitch"            => "true",
  "neutron"                       => "false",
  "ssl"                           => "false",
  "freeipa"                       => "false",
  "mysql_ca"                      => "/etc/ipa/ca.crt",
  "mysql_cert"                    => "/etc/pki/tls/certs/PRIV_HOST-mysql.crt",
  "mysql_key"                     => "/etc/pki/tls/private/PRIV_HOST-mysql.key",
  "qpid_ca"                       => "/etc/ipa/ca.crt",
  "qpid_cert"                     => "/etc/pki/tls/certs/PRIV_HOST-qpid.crt",
  "qpid_key"                      => "/etc/pki/tls/private/PRIV_HOST-qpid.key",
  "horizon_ca"                    => "/etc/ipa/ca.crt",
  "horizon_cert"                  => "/etc/pki/tls/certs/PUB_HOST-horizon.crt",
  "horizon_key"                   => "/etc/pki/tls/private/PUB_HOST-horizon.key",
  "qpid_nssdb_password"           => SecureRandom.hex,
  "fence_xvm_key_file_password"   => SecureRandom.hex,
}

def get_key_type(value)
  key_list = LookupKey::KEY_TYPES
  value_type = value.class.to_s.downcase
  if key_list.include?(value_type)
   value_type
  elsif [FalseClass, TrueClass].include? value.class
    'boolean'
  end
  # If we need to handle actual number classes like Fixnum, add those here
end


# key (:ha, etc) is only  used internally for referencing from roles
layouts = {
  :ha_nova        => Staypuft::Layout.where(:name => "Distributed with High Availability",
                                            :networking => "nova").first_or_create!,
  :non_ha_nova    => Staypuft::Layout.where(:name => "Distributed",
                                            :networking => "nova").first_or_create!,
  :ha_neutron     => Staypuft::Layout.where(:name => "Distributed with High Availability",
                                            :networking => "neutron").first_or_create!,
  :non_ha_neutron => Staypuft::Layout.where(:name => "Distributed",
                                            :networking => "neutron").first_or_create!,
}

# services don't have puppetclasses yet, since they aren't broken out on the back end
services = {
  :non_ha_qpid        => {:name => "qpid (non-HA)", :class => []},
  :mysql              => {:name => "MySQL", :class => []},
  :non_ha_keystone    => {:name => "Keystone (non-HA)", :class => []},
  :nova_controller    => {:name => "Nova (Controller)", :class => []},
  :neutron_controller => {:name => "Neutron (Controller)", :class => []},
  :non_ha_glance      => {:name => "Glance (non-HA)", :class => []},
  :cinder             => {:name => "Cinder", :class => []},
  :heat               => {:name => "Heat", :class => []},
  :ceilometer         => {:name => "Ceilometer", :class => []},
  :neutron_l3         => {:name => "Neutron - L3", :class => []},
  :dhcp               => {:name => "DHCP", :class => []},
  :ovs                => {:name => "OVS", :class => []},
  :nova_compute       => {:name => "Nova-compute", :class => []},
  :neutron_compute    => {:name => "Neutron-compute", :class => []},
  :neutron_ovs_agent  => {:name => "Neutron-ovs-agent", :class => []},
  :swift              => {:name => "Swift", :class => []},
  :ha_controller      => {:name => "HA (Controller)", :class => ["quickstack::openstack_common",
                                                                 "quickstack::pacemaker::common",
                                                                 "quickstack::pacemaker::params"]},
  :keystone_ha           => {:name => "Keystone (HA)", :class => ["quickstack::pacemaker::keystone"]},
  :load_balancer_ha      => {:name => "Load Balancer (HA)", :class => ["quickstack::pacemaker::load_balancer"]},
  :memcached_ha          => {:name => "Memcached (HA)", :class => ["quickstack::pacemaker::memcached"]},
  :qpid_ha               => {:name => "qpid (HA)", :class => ["quickstack::pacemaker::qpid",
                                                      "qpid::server"]},
  :glance_ha             => {:name => "Glance (HA)", :class => ["quickstack::pacemaker::glance"]},
  :nova_ha               => {:name => "Nova (HA)", :class => ["quickstack::pacemaker::nova"]},
  :ha_db_temp            => {:name => "Database (HA -- temp)", :class => ["quickstack::hamysql::singlenodetest"]}
}
services.each do |skey, svalue|
  service = Staypuft::Service.where(:name=>svalue[:name]).first_or_create!

  # set params in puppetclass
  pclassnames = svalue[:class].kind_of?(Array) ? svalue[:class] : [ svalue[:class] ]
  service.puppetclasses = pclassnames.collect do |pclassname|
    pclass = Puppetclass.find_by_name pclassname
    # skip if puppet class isn't found (yet)
    if pclass
      pclass.class_params.each do |p|
        if params.include?(p.key)
          p.key_type = get_key_type(params[p.key])
          p.default_value = params[p.key]
        end
        p.override = true
        p.save!
      end
      pclass
    end
  end.compact

  service.description = svalue[:description]
  service.save!
  svalue[:obj] = service
end

# The list of roles is still from astapor
# FIXME for now layouts are different based on Nova vs. Neutron networks. This is
#  actually incorrect, but it's a placeholder example of how layouts might differ
# until we get the real list of roles per layout
# layout refs below specify layout keys from layouts hash
roles = [
    {:name=>"Controller (Nova)",
     :class=>"quickstack::nova_network::controller",
     :layouts=>[[:non_ha_nova, 2]],
     :services=>[:non_ha_qpid, :mysql, :non_ha_keystone, :nova_controller, :non_ha_glance, :cinder, :heat, :ceilometer]},
    {:name=>"Compute (Nova)",
     :class=>"quickstack::nova_network::compute",
     :layouts=>[[:ha_nova, 10], [:non_ha_nova, 10]],
     :services=>[:nova_compute]},
    {:name=>"Controller (Neutron)",
     :class=>"quickstack::neutron::controller",
     :layouts=>[[:non_ha_neutron, 2]],
     :services=>[:non_ha_qpid, :mysql, :non_ha_keystone, :neutron_controller, :non_ha_glance, :cinder, :heat, :ceilometer]},
    {:name=>"Compute (Neutron)",
     :class=>"quickstack::neutron::compute",
     :layouts=>[[:ha_neutron, 10], [:non_ha_neutron, 10]],
     :services=>[:neutron_compute, :neutron_ovs_agent]},
    {:name=>"Neutron Networker",
     :class=>"quickstack::neutron::networker",
     :layouts=>[[:non_ha_neutron, 3]],
     :services=>[:neutron_l3, :dhcp, :ovs]},
    {:name=>"LVM Block Storage",
     :class=>"quickstack::storage_backend::lvm_cinder",
     :layouts=>[[:ha_nova, 1], [:ha_neutron, 1], [:non_ha_nova, 1], [:non_ha_neutron, 1]],
     :services=>[:cinder]},
    {:name=>"Swift Storage Node",
     :class=>"quickstack::swift::storage",
     :layouts=>[[:ha_nova, 5], [:ha_neutron, 5], [:non_ha_nova, 5], [:non_ha_neutron, 5]],
     :services=>[:swift]},
    {:name=>"HA Controller (Nova)",
     :class=>[],
     :layouts=>[[:ha_nova, 3]],
     :services=>[:ha_controller, :keystone_ha, :load_balancer_ha, :memcached_ha, :qpid_ha, :glance_ha, :nova_ha]},
    {:name=>"HA Controller (Neutron)",
     :class=>[],
     :layouts=>[[:ha_neutron, 2]],
     :services=>[]},
         # this one is temporary -- goes away once db is added back to HA COntroller
    {:name=>"HA Database (temporary)",
     :class=>[],
     :layouts=>[[:ha_nova, 2]],
     :services=>[:ha_db_temp]}
        ]

roles.each do |r|
  #create role
  role = Staypuft::Role.where(:name => r[:name]).first_or_create!

  # set params in puppetclass
  pclassnames = r[:class].kind_of?(Array) ? r[:class] : [ r[:class] ]
  role.puppetclasses = pclassnames.collect do |pclassname|
    pclass = Puppetclass.find_by_name pclassname
    # skip if puppet class isn't found (yet)
    if pclass
      pclass.class_params.each do |p|
        if params.include?(p.key)
          p.key_type = get_key_type(params[p.key])
          p.default_value = params[p.key]
        end
        p.override = true
        p.save!
      end
      pclass
    end
  end.compact

  role.description = r[:description]
  old_role_services_arr = role.role_services.to_a
  r[:services].each do |key|
    role_service = role.role_services.where(:service_id => services[key][:obj].id).first_or_create!
    old_role_services_arr.delete(role_service)
  end
  # delete any prior mappings that remain
  old_role_services_arr.each do |role_service|
    role.services.destroy(role_service.service)
  end
  role.save!
  old_layout_roles_arr = role.layout_roles.to_a
  r[:layouts].each do |layout, deploy_order|
    layout_role = role.layout_roles.where(:layout_id => layouts[layout].id).first_or_initialize
    layout_role.deploy_order = deploy_order
    layout_role.save!
    old_layout_roles_arr.delete(layout_role)
  end
  # delete any prior mappings that remain
  old_layout_roles_arr.each do |layout_role|
    role.layouts.destroy(layout_role.layout)
  end
end
