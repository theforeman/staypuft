module Staypuft
  module HostsHelper

    def list_subnet_types(nic, subnets)
      types = {}

      return types if nic.host.nil? || nic.host.deployment.nil?

      subnets.each do |subnet|
        types[subnet.id] = subnet_types(nic.host.deployment, subnet)
      end

      return types
    end

  end
end
