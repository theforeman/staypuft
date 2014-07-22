module Staypuft
  class SubnetTypingsController < ActionController::Base
    def create
      @deployment = Deployment.find(params[:deployment_id])
      @subnet_type = SubnetType.find(params[:subnet_type_id])
      @subnet = Subnet.find(params[:subnet_id])
      @subnet_typing = @deployment.subnet_typings.new(:subnet_id => @subnet.id, :subnet_type_id => @subnet_type.id)
      @saved = @subnet_typing.save
    end

    def update
      @subnet_typing = SubnetTyping.find(params[:id])
      @subnet_type = @subnet_typing.subnet_type
      @subnet = Subnet.find(params[:subnet_id])
      @subnet_typing.subnet = @subnet
      @saved = @subnet_typing.save
    end

    def destroy
      @subnet_typing = SubnetTyping.find(params[:id])
      @subnet_type = @subnet_typing.subnet_type
      @destroyed = @subnet_typing.destroy
    end
  end
end
