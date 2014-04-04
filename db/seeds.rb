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
  "horizon_secret_key"            => SecureRandom.hex,
  "keystone_admin_token"          => SecureRandom.hex,
  "keystone_db_password"          => SecureRandom.hex,
  "mysql_root_password"           => SecureRandom.hex,
  "neutron_db_password"           => SecureRandom.hex,
  "neutron_user_password"         => SecureRandom.hex,
  "nova_db_password"              => SecureRandom.hex,
  "nova_user_password"            => SecureRandom.hex,
  "nova_default_floating_pool"    => "nova",
  "swift_admin_password"          => SecureRandom.hex,
  "swift_shared_secret"           => SecureRandom.hex,
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
  "admin_email"                   => "admin@#{Facter.domain}",
  "neutron_metadata_proxy_secret" => SecureRandom.hex,
  "enable_ovs_agent"              => "true",
  "ovs_vlan_ranges"               => '',
  "ovs_bridge_mappings"           => [],
  "ovs_bridge_uplinks"            => [],
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
  "pacemaker_cluster_name"        => "openstack",
  "pacemaker_cluster_members"     => "192.168.200.10 192.168.200.11 192.168.200.12",
  "pacemaker_disable_stonith"     => false,
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
  :qpid               => {:name => "qpid", :class => nil},
  :mysql              => {:name => "MySQL", :class => nil},
  :keystone           => {:name => "Keystone", :class => nil},
  :nova_controller    => {:name => "Nova (Controller)", :class => nil},
  :neutron_controller => {:name => "Neutron (Controller)", :class => nil},
  :glance             => {:name => "Glance", :class => nil},
  :cinder             => {:name => "Cinder", :class => nil},
  :heat               => {:name => "Heat", :class => nil},
  :ceilometer         => {:name => "Ceilometer", :class => nil},
  :neutron_l3         => {:name => "Neutron - L3", :class => nil},
  :dhcp               => {:name => "DHCP", :class => nil},
  :ovs                => {:name => "OVS", :class => nil},
  :nova_compute       => {:name => "Nova-compute", :class => nil},
  :neutron_compute    => {:name => "Neutron-compute", :class => nil},
  :neutron_ovs_agent  => {:name => "Neutron-ovs-agent", :class => nil},
  :swift              => {:name => "Swift", :class => nil}
}
services.each do |skey, svalue|
  service = Staypuft::Service.where(:name=>svalue[:name]).first_or_create!

  # set params in puppetclass
  if svalue[:class]
    pclass = Puppetclass.find_by_name svalue[:class]
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
      service.puppetclasses = [ pclass ]
    end
  end

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
     :layouts=>[[:ha_nova, 1], [:non_ha_nova, 1]],
     :services=>[:qpid, :mysql, :keystone, :nova_controller, :glance, :cinder, :heat, :ceilometer]},
    {:name=>"Compute (Nova)",
     :class=>"quickstack::nova_network::compute",
     :layouts=>[[:ha_nova, 10], [:non_ha_nova, 10]],
     :services=>[:nova_compute]},
    {:name=>"Controller (Neutron)",
     :class=>"quickstack::neutron::controller",
     :layouts=>[[:ha_neutron, 1], [:non_ha_neutron, 1]],
     :services=>[:qpid, :mysql, :keystone, :neutron_controller, :glance, :cinder, :heat, :ceilometer]},
    {:name=>"Compute (Neutron)",
     :class=>"quickstack::neutron::compute",
     :layouts=>[[:ha_neutron, 10], [:non_ha_neutron, 10]],
     :services=>[:neutron_compute, :neutron_ovs_agent]},
    {:name=>"Neutron Networker",
     :class=>"quickstack::neutron::networker",
     :layouts=>[[:ha_neutron, 2]],
     :services=>[:neutron_l3, :dhcp, :ovs]},
    {:name=>"LVM Block Storage",
     :class=>"quickstack::storage_backend::lvm_cinder",
     :layouts=>[[:ha_nova, 3], [:ha_neutron, 3], [:non_ha_nova, 3], [:non_ha_neutron, 3]],
     :services=>[:cinder]},
    {:name=>"Load Balancer",
     :class=>"quickstack::load_balancer",
     :layouts=>[[:ha_nova, 4], [:ha_neutron, 4]],
     :services=>[]}
        ]

roles.each do |r|
  #create role
  role = Staypuft::Role.where(:name => r[:name]).first_or_create!

  # set params in puppetclass
  if r[:class]
    pclass = Puppetclass.find_by_name r[:class]
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
      role.puppetclasses = [ pclass ]
    end
  end

  role.description = r[:description]
  r[:services].each do |key|
    role.id
    services[key]
    services[key][:obj]
    services[key][:obj].id
    Staypuft::RoleService.where(:role_id => role.id, :service_id => services[key][:obj].id).first
    Staypuft::RoleService.where(:role_id => role.id, :service_id => services[key][:obj].id).first_or_create!
  end
  role.save!
  r[:layouts].each do |layout, deploy_order|
    layout_role = Staypuft::LayoutRole.where(:role_id => role.id, :layout_id => layouts[layout].id).first_or_initialize
    layout_role.deploy_order = deploy_order
    layout_role.save!
  end
end
