module Staypuft
  class SubnetTypingsController < ActionController::Base
    def create
      @deployment = Deployment.find(params[:deployment_id])
      @subnet_type = SubnetType.find(params[:subnet_type_id])
      @subnet = Subnet.find(params[:subnet_id])
      check_for_existing_assignments
      @subnet_typing = @deployment.subnet_typings.new(:subnet_id => @subnet.id, :subnet_type_id => @subnet_type.id)
      @saved = @subnet_typing.save
    end

    def update
      @subnet_typing = SubnetTyping.find(params[:id])
      @deployment = @subnet_typing.deployment
      @subnet_type = @subnet_typing.subnet_type
      @subnet = Subnet.find(params[:subnet_id])
      check_for_existing_assignments
      @subnet_typing.subnet = @subnet
      @saved = @subnet_typing.save
    end

    def destroy
      @subnet_typing = SubnetTyping.find(params[:id])
      @deployment = @subnet_typing.deployment
      @subnet = @subnet_typing.subnet
      check_for_existing_assignments
      @subnet_type = @subnet_typing.subnet_type
      @destroyed = @subnet_typing.destroy
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
  end
end
