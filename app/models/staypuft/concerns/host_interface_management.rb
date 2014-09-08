module Staypuft
  module Concerns
    module HostInterfaceManagement
      extend ActiveSupport::Concern

      included do

      end

      def clean_vlan_interfaces
        self.interfaces.virtual.map(&:destroy)
      end

      def interfaces_identifiers
        interfaces = [ self.primary_interface ]
        interfaces += self.respond_to?(:interfaces) ? self.interfaces.where("type <> 'Nic::BMC'").where("identifier NOT LIKE 'vip%'").physical.map(&:identifier) : []
        interfaces
      end

      def make_all_interfaces_managed
        self.interfaces.each do |interface|
          interface.managed = true
          interface.save!
        end
      end

      def build_vips(parameters)
        deployment = self.hostgroup.deployment
        typings = deployment.subnet_typings
        types = SubnetType.where(:name => parameters.values).all
        n = 0

        parameters.each do |parameter, subnet_type|
          type = types.find { |t| t.name == subnet_type }
          raise "unable to find subnet type with name #{subnet_type}" if type.nil?

          subnet = typings.where(:subnet_type_id => type.id).first.subnet
          raise "unable to find subnet assigned to type #{subnet_type} in deployment #{deployment.name}" if subnet.nil?

          interface = self.interfaces.build(:type => 'Nic::Managed')
          interface.identifier = "vip#{n}"
          interface.subnet = subnet
          interface.managed = false
          interface.mac = "00:00:00:00:00:#{n.to_s(16).rjust(2, '0')}"
          interface.tag = parameter
          n += 1
        end
      end
    end
  end
end
