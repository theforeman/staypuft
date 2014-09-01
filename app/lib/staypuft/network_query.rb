module Staypuft
  class NetworkQuery

    def initialize(deployment)
      @deployment = deployment
    end

    def interface_for_host(host, subnet_type_name)
      subnet_type = @deployment.layout.subnet_types.where(:name=> subnet_type_name).first

      # raise error if no subnet with this name is assigned to this layout
      # TODO: should this just return nil instead of raising an error?
      if subnet_type.nil?
        raise ArgumentError, "Invalid import file: subnet type  '#{subnet_type_name}' node found for deployment #{@deployment.name}"
      end

      subnet_typing = @deployment.subnet_typings.where(:subnet_type_id => subnet_type.id).first
      # if this subnet type isn't assigned to a subnet for this deployment, return nil
      return nil if subnet_typing.nil?
      subnet = subnet_typing.subnet

      # check for physical interface
      iface = host.interfaces.physical.where(:subnet_id => subnet.id).first
      return iface unless iface.nil?

      # check for virtual interface
      iface = host.interfaces.virtual.where(:subnet_id => subnet.id).first
      return iface unless iface.nil?

      # no matches found; return nil
      nil
    end
  end
end
