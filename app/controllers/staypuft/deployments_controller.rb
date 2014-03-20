module Staypuft
  class DeploymentsController < ApplicationController
    def index
      @deployments = Deployment.all
    end

    def new
      base_hostgroup = Hostgroup.where(:name => "base_hostgroup").first_or_create!

      deployment = Deployment.new(:name => SecureRandom.hex)
      deployment.description = "This is a deployment"
      deployment.layout = Layout.where(:name => "Distributed",
                                                 :networking => "neutron").first
      deployment_hostgroup = Hostgroup.new(:name => deployment.name)
      deployment_hostgroup.parent_id = base_hostgroup.id
      deployment_hostgroup.save!

      deployment.hostgroup = deployment_hostgroup
      deployment.save!

      redirect_to deployment_steps_path
    end

    def show
      @hostgroups = Hostgroup.all
    end
  end
end
