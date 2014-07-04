module Staypuft
  class SubnetTypingsController < ActionController::Base
    def create
      @deployment = Deployment.find(params[:deployment_id])
      @subnet_type = SubnetType.find(params[:subnet_type_id])
      @subnet = Subnet.find(params[:subnet_id])
      @subnet_typing = @deployment.subnet_typings.new(:subnet_id => @subnet.id, :subnet_type_id => @subnet_type.id)
      @saved = @subnet_typing.save
    end

    def destroy
      @subnet_typing = SubnetTyping.find(params[:id]).destroy
      @destroyed = @subnet_typing
    end
  end
end
