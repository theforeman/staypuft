module Staypuft
  class SubnetTypingsController < ActionController::Base
    def create
      @errors = {}
      @deployment = Deployment.find(params[:deployment_id])
      @subnet_type = SubnetType.find(params[:subnet_type_id])
      @subnet = Subnet.find(params[:subnet_id])
      check_for_existing_assignments
      check_for_ip_management
      check_public_api_for_default_gateway
      check_for_unsharable_subnet_types
      @subnet_typing = @deployment.subnet_typings.new(:subnet_id => @subnet.id, :subnet_type_id => @subnet_type.id)
      @saved = @errors.blank? ? @subnet_typing.save : false
    end

    def update
      @errors = {}
      @subnet_typing = SubnetTyping.find(params[:id])
      @deployment = @subnet_typing.deployment
      @subnet_type = @subnet_typing.subnet_type
      @subnet = Subnet.find(params[:subnet_id])
      check_for_existing_assignments
      check_for_ip_management
      check_public_api_for_default_gateway
      check_for_unsharable_subnet_types
      @subnet_typing.subnet = @subnet
      @saved = @errors.blank? ? @subnet_typing.save : false
    end

    def destroy
      @errors = {}
      @subnet_typing = SubnetTyping.find(params[:id])
      @deployment = @subnet_typing.deployment
      @subnet = @subnet_typing.subnet
      check_for_existing_assignments
      @subnet_type = @subnet_typing.subnet_type
      if @subnet_type.is_required
        @errors[@subnet_type.name] = ["Network traffic type is required."]
      end
      @destroyed = @errors.blank? ? @subnet_typing.destroy : false
    end

    private

    def check_for_existing_assignments
      existing = @deployment.hosts.includes(:interfaces).any? do |h|
        h.subnet_id == @subnet.id || h.interfaces.any? { |i| i.subnet_id == @subnet.id }
      end
      if existing
        @warn = _('Some hosts interfaces were already assigned to this subnet, check interface assignment before deploying!')
      end
    end

    def check_for_ip_management
      if @subnet_type.foreman_managed_ips &&
        !((@subnet.ipam == Subnet::IPAM_MODES[:dhcp] && @subnet.dhcp_boot_mode?) ||
          (@subnet.ipam == Subnet::IPAM_MODES[:db] && !@subnet.dhcp_boot_mode?))
        @errors[@subnet_type.name] = ["Foreman-managed IP addresses are required to associate with subnet."]
        false
      else
        true
      end
    end

    def check_for_unsharable_subnet_types
      # if subnet type is unsharable, make sure nothing else is already assigned here
      if @subnet_type.dedicated_subnet
        if @deployment.subnet_typings.where(:subnet_id => @subnet.id).size > 0
          @errors[@subnet_type.name] = ["Subnet cannot be shared with other traffic types in this deployment."]
          false
        else
          true
        end
      #otherwise make sure there's no existing unsharable type already here
      else
        existing_dedicated_types = @deployment.subnet_typings.includes(:subnet_type).where(:subnet_id => @subnet.id, "staypuft_subnet_types.dedicated_subnet" => true)
        if existing_dedicated_types.size > 0
          @errors[existing_dedicated_types.first.subnet_type.name] = ["Subnet cannot be shared with other traffic types in this deployment."]
          false
        else
          true
        end
      end
    end

    def check_public_api_for_default_gateway
      if @subnet_type.name == Staypuft::SubnetType::PUBLIC_API && @subnet.gateway.empty?
        @errors[@subnet_type.name] = ["Subnet must have a default gateway defined."]
      end
    end
  end
end
