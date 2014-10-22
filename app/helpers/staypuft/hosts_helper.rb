module Staypuft
  module HostsHelper

    def list_subnet_types_for_nic(nic, subnets)
      list_subnet_types_for_host(nic.host, subnets)
    end

    def list_subnet_types_for_host(host, subnets)
      types = {}

      return types if host.nil? || host.deployment.nil?

      subnets.each do |subnet|
        types[subnet.id] = subnet_types(host.deployment, subnet)
      end

      return types
    end

  end
end
