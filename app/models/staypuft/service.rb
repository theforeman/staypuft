module Staypuft
  class Service < ActiveRecord::Base
    has_many :role_services, :dependent => :destroy
    has_many :roles, :through => :role_services
    has_many :hostgroups, :through => :roles

    has_many :service_classes, :dependent => :destroy
    has_many :puppetclasses, :through => :service_classes

    attr_accessible :description, :name

    validates  :name, :presence => true, :uniqueness => true

    # for each service, a list of param names. Optionally, instead of a string
    # for a param name, an array of [param_name, puppetclass] in the case where
    # there are possibly multiple puppetclass matches. without this, we'll
    # just grab the first puppetclass from the matching hostgroup
    UI_PARAMS = { 
      "qpid (non-HA)"=> ["qpid_ca", "qpid_cert", "qpid_host", "qpid_key", "qpid_nssdb_password"],
      "MySQL"=> ["mysql_ca", "mysql_cert", "mysql_host", "mysql_key",
                 "mysql_root_password"],
      "Keystone (non-HA)"=> ["keystone_admin_token", "keystone_db_password"],
      "Nova (Controller)"=> ["admin_email", "admin_password", "auto_assign_floating_ip",
                             "controller_admin_host", "controller_priv_host",
                             "controller_pub_host", "freeipa", "horizon_ca",
                             "horizon_cert", "horizon_key", "horizon_secret_key",
                             "nova_db_password", "nova_user_password", "ssl",
                             "swift_admin_password", "swift_ringserver_ip",
                             "swift_shared_secret", "swift_storage_device",
                             "swift_storage_ips"],
      "Neutron (Controller)" => ["admin_email", "admin_password",
                                 "cisco_nexus_plugin", "cisco_vswitch_plugin",
                                 "controller_admin_host", "controller_priv_host",
                                 "controller_pub_host", "enable_tunneling",
                                 "freeipa", "horizon_ca", "horizon_cert",
                                 "horizon_key", "horizon_secret_key",
                                 "ml2_flat_networks", "ml2_install_deps",
                                 "ml2_mechanism_drivers", "ml2_network_vlan_ranges",
                                 "ml2_tenant_network_types", "ml2_tunnel_id_ranges",
                                 "ml2_type_drivers", "ml2_vni_ranges",
                                 "ml2_vxlan_group", "neutron_core_plugin",
                                 "neutron_db_password", "neutron_metadata_proxy_secret",
                                 "neutron_user_password", "nexus_config",
                                 "nexus_credentials", "nova_db_password",
                                 "nova_user_password", "ovs_vlan_ranges",
                                 "provider_vlan_auto_create", "provider_vlan_auto_trunk",
                                 "ssl", "tenant_network_type", "tunnel_id_ranges",
                                 "verbose",
                                 "swift_admin_password", "swift_ringserver_ip",
                                 "swift_shared_secret", "swift_storage_device",
                                 "swift_storage_ips"],
      "Glance (non-HA)"=> ["glance_db_password", "glance_user_password"],
      "Cinder"=> ["cinder_backend_gluster", "cinder_backend_iscsi",
                  "cinder_db_password", "cinder_gluster_servers",
                  "cinder_gluster_volume", "cinder_user_password"],
      "Heat"=> ["heat_cfn", "heat_cloudwatch", "heat_db_password", "heat_user_password"],
      "Ceilometer"=> ["ceilometer_metering_secret", "ceilometer_user_password"
                     ],
      "Neutron - L3" => ["controller_priv_host", "enable_tunneling",
                         "external_network_bridge", "fixed_network_range",
                         "mysql_ca", "mysql_host", "neutron_db_password",
                         "neutron_metadata_proxy_secret", "neutron_user_password",
                         "nova_db_password", "nova_user_password",
                         "qpid_host", "ssl",
                         "tenant_network_type", "tunnel_id_ranges", "verbose"],
      "DHCP" => [],
      "OVS" => ["ovs_bridge_mappings", "ovs_bridge_uplinks",
                "ovs_tunnel_iface", "ovs_tunnel_network", "ovs_tunnel_types",
                "ovs_vlan_ranges", "ovs_vxlan_udp_port" ],
      "Nova-compute" => ["admin_password", "auto_assign_floating_ip",
                         "ceilometer_metering_secret", "ceilometer_user_password",
                         "cinder_backend_gluster", "controller_priv_host",
                         "controller_pub_host", "fixed_network_range",
                         "floating_network_range", "mysql_ca", "mysql_host",
                         "nova_db_password", "network_private_iface",
                         "network_private_network", 
                         "network_public_iface",
                         "network_public_network", "nova_user_password",
                         "qpid_host", "ssl", "verbose", "use_qemu_for_poc"],
      "Neutron-compute" => ["admin_password", "ceilometer_metering_secret",
                            "ceilometer_user_password", "cinder_backend_gluster",
                            "controller_admin_host", "controller_priv_host",
                            "controller_pub_host", "enable_tunneling", "mysql_ca",
                            "mysql_host", "neutron_core_plugin",
                            "neutron_db_password", "neutron_user_password",
                            "nova_db_password", "nova_user_password",
                            "ovs_bridge_mappings", "ovs_tunnel_iface",
                            "ovs_tunnel_network", "ovs_tunnel_types", "ovs_vlan_ranges",
                            "ovs_vxlan_udp_port", "qpid_host", "ssl",
                            "tenant_network_type", "tunnel_id_ranges", "verbose",
                            "use_qemu_for_poc"],
      "Neutron-ovs-agent"=> [],
      "Swift (node)" => ["swift_all_ips", "swift_ext4_device", "swift_local_interface",
                         "swift_local_network","swift_loopback", "swift_ring_server",
                         "swift_shared_secret"]

    }

    def ui_params_for_form(hostgroup = self.hostgroups.first)
      return [] if (hostgroup.nil?)
      if hostgroup.puppetclasses.blank?
        params_from_hash = []
      else
        puppetclass = hostgroup.puppetclasses.first
        params_from_hash = UI_PARAMS.fetch(self.name,[]).collect do |param_key|
          if param_key.is_a?(Array)
            param_name = param_key[0]
            param_puppetclass = Puppetclass.find_by_name(param_key[1])
          else
            param_name = param_key
            param_puppetclass = puppetclass
          end
          param_lookup_key = param_puppetclass.class_params.where(:key=>param_key).first
          param_lookup_key.nil? ? nil : {:hostgroup => hostgroup,
                                         :puppetclass => param_puppetclass,
                                         :param_key => param_lookup_key}
        end.compact
      end
      params_from_service = self.puppetclasses.collect do |pclass|
        pclass.class_params.collect do |class_param|
          {:hostgroup => hostgroup, :puppetclass => pclass, :param_key => class_param}
        end
      end.flatten
      params_from_hash + params_from_service
    end
  end
end
