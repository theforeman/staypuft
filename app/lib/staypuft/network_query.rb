module Staypuft
  class NetworkQuery

    def initialize(deployment)
      @deployment = deployment
    end

    def ip_for_host(host, subnet_type_name)
      interface_hash_for_host(host, subnet_type_name)[:ip]
    end

    def interface_for_host(host, subnet_type_name)
      interface_hash_for_host(host, subnet_type_name)[:interface]
    end

    class Jail < Safemode::Jail
      allow :ip_for_host, :interface_for_host
    end

    private
    def interface_hash_for_host(host, subnet_type_name)
      if host.nil?
        raise ArgumentError, "no host specified"
      end

      subnet_type = @deployment.layout.subnet_types.where(:name=> subnet_type_name).first

      # raise error if no subnet with this name is assigned to this layout
      if subnet_type.nil?
        raise ArgumentError, "Invalid subnet type  '#{subnet_type_name}' for layout of this deployment #{@deployment.name}"
      end

      subnet_typing = @deployment.subnet_typings.where(:subnet_type_id => subnet_type.id).first
      # if this subnet type isn't assigned to a subnet for this deployment, return nil
      return {} if subnet_typing.nil?
      subnet = subnet_typing.subnet

      secondary_iface = host.interfaces.where(:subnet_id => subnet.id).first
      # check for primary interface
      if (host.subnet_id == subnet.id)
        {:subnet => host.subnet, :ip => host.ip,
         :interface => host.primary_interface, :mac =>  host.mac }
      elsif !secondary_iface.nil?
        {:subnet => secondary_iface.subnet, :ip => secondary_iface.ip,
         :interface => secondary_iface.identifier, :mac =>  secondary_iface.mac }
      else
        {}
      end
    end
  end
end
