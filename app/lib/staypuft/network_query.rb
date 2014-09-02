module Staypuft
  class NetworkQuery

    def initialize(deployment)
      @deployment = deployment
    end

    def interface_for_host(host, subnet_type_name)
      subnet_type = @deployment.layout.subnet_types.where(:name=> subnet_type_name).first

      # raise error if no subnet with this name is assigned to this layout
      if subnet_type.nil?
        raise ArgumentError, "Invalid subnet type  '#{subnet_type_name}' for layout of this deployment #{@deployment.name}"
      end

      subnet_typing = @deployment.subnet_typings.where(:subnet_type_id => subnet_type.id).first
      # if this subnet type isn't assigned to a subnet for this deployment, return nil
      return nil if subnet_typing.nil?
      subnet = subnet_typing.subnet

      # check for primary interface
      # FIXME: we should really return some consistent interface type or hash here,
      # so we'll need to change this to return some internal Staypuft interface object
      # here that works for both primary and secondary interfaces
      return host if (host.subnet_id == subnet.id)

      # return interface
      host.interfaces.where(:subnet_id => subnet.id).first
    end
  end
end
