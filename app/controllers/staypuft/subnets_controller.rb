module Staypuft
  class SubnetsController < Staypuft::ApplicationController

    layout false

    before_filter :get_deployment

    def new
      @simple_subnet = SimpleSubnet.new
    end

    def create
      @simple_subnet = SimpleSubnet.new(params[:staypuft_simple_subnet])
      @simple_subnet.deployment = @deployment
      @result = @simple_subnet.save
    end

    private

    def get_deployment
      @deployment = Deployment.find(params[:deployment_id])
    end

  end
end
