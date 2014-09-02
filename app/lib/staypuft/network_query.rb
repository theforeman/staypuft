module Staypuft
  class NetworkQuery

    def initialize(deployment)
      @deployment = deployment
    end

    private
    def interface_hash_for_host(host, subnet_type_name)
      subnet_type = @deployment.layout.subnet_types.where(:name=> subnet_type_name).first

      # raise error if no subnet with this name is assigned to this layout
      if subnet_type.nil?
        raise ArgumentError, "Invalid subnet type  '#{subnet_type_name}' for layout of this deployment #{@deployment.name}"
      end

      subnet_typing = @deployment.subnet_typings.where(:subnet_type_id => subnet_type.id).first
      # if this subnet type isn't assigned to a subnet for this deployment, return nil
      return nil if subnet_typing.nil?
      subnet = subnet_typing.subnet

      secondary_iface = host.interfaces.where(:subnet_id => subnet.id).first
      # check for primary interface
      if (host.subnet_id == subnet.id)
        {:subnet => host.subnet, :ip => host.ip,
         :interface => host.primary_interface, :mac =>  host.mac }
      elsif !iface.nil?
        {:subnet => secondary_iface.subnet, :ip => secondary_iface.ip,
         :interface => secondary_iface.name, :mac =>  secondary_iface.mac }
      else
        nil
      end
    end
  end
end
