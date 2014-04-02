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
      "qpid"=> ["qpid_ca", "qpid_cert", "qpid_host", "qpid_key", "qpid_nssdb_password"],
      "MySQL"=> ["mysql_ca", "mysql_cert", "mysql_host", "mysql_key",
                 "mysql_root_password"],
      "Keystone"=> ["keystone_admin_token", "keystone_db_password"],
      "Nova (Controller)"=> ["admin_email", "admin_password", "auto_assign_floating_ip",
                             "controller_admin_host", "controller_priv_host",
                             "controller_pub_host", "freeipa", "horizon_ca",
                             "horizon_cert", "horizon_key", "horizon_secret_key",
                             "nova_db_password", "nova_user_password", "ssl"],
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
                                 "verbose"],
      "Glance"=> ["glance_db_password", "glance_user_password"],
      "Cinder"=> ["cinder_backend_gluster", "cinder_backend_iscsi",
                  "cinder_db_password", "cinder_gluster_servers",
                  "cinder_gluster_volume", "cinder_user_password"],
      "Heat"=> ["heat_cfn", "heat_cloudwatch", "heat_db_password", "heat_user_password"],
      "Ceilometer"=> ["ceilometer_metering_secret", "ceilometer_user_password"
                     ],
      "Neutron - L3" => [],
      "DHCP" => [],
      "OVS" => [],
      "Nova-compute" => ["admin_password", "auto_assign_floating_ip",
                         "ceilometer_metering_secret", "ceilometer_user_password",
                         "cinder_backend_gluster", "controller_priv_host",
                         "controller_pub_host", "fixed_network_range",
                         "floating_network_range", "mysql_ca", "mysql_host",
                         "nova_db_password", "nova_network_private_iface",
                         "nova_network_public_iface", "nova_user_password",
                         "qpid_host", "ssl", "verbose"],
      "Neutron-compute" => ["admin_password", "ceilometer_metering_secret",
                            "ceilometer_user_password", "cinder_backend_gluster",
                            "controller_admin_host", "controller_priv_host",
                            "controller_pub_host", "enable_tunneling", "mysql_ca",
                            "mysql_host", "neutron_core_plugin",
                            "neutron_db_password", "neutron_user_password",
                            "nova_db_password", "nova_user_password",
                            "ovs_bridge_mappings", "ovs_tunnel_iface",
                            "ovs_tunnel_types", "ovs_vlan_ranges",
                            "ovs_vxlan_udp_port", "qpid_host", "ssl",
                            "tenant_network_type", "tunnel_id_ranges", "verbose"],
      "Neutron-ovs-agent"=> [],
      "Swift" => ["swift_admin_password", "swift_ringserver_ip",
                  "swift_shared_secret", "swift_storage_device",
                  "swift_storage_ips"]
    }

    def ui_params_for_form(hostgroup = self.hostgroups.first)
      return [] if (hostgroup.nil? || hostgroup.puppetclasses.nil?)
      puppetclass = hostgroup.puppetclasses.first
      # nil puppetclass means grab the first one from matching hostgroup
      UI_PARAMS[self.name].collect do |param_key|
        if param_key.is_a?(Array)
          param_name = param_key[0]
          param_puppetclass = param_key[1]
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
  end
end
