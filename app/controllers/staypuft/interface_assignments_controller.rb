module Staypuft
  class InterfaceAssignmentsController < Staypuft::ApplicationController
    def index
      @deployment = Deployment.find(params[:deployment_id])
      @hosts = Host::Managed.where(:id => params[:host_ids])
      @subnets = @deployment.subnets.uniq
      @host = @hosts.first
      @interfaces = @host ? @host.interfaces.where("type <> 'Nic::BMC'").order(:identifier).physical : []
    end

    def create
      @errors = {}
      @deployment = Deployment.find(params[:deployment_id])
      @hosts = Host::Managed.where(:id => params[:host_ids])
      @hosts.each do |host|
        @interface = host.interfaces.find_by_identifier(params[:interface]) || host
        @subnet = Subnet.find(params[:subnet_id])
        @assigner = InterfaceAssigner.new(@deployment, @interface, @subnet)
        @assigner.assign
        @errors[host.name] = @assigner.errors if @assigner.errors.present?
      end
      @saved = @errors.blank?
    end

    def destroy
      @errors = {}
      @deployment = Deployment.find(params[:deployment_id])
      @hosts = Host::Managed.where(:id => params[:host_ids])
      @hosts.each do |host|
        @interface = host.interfaces.find_by_identifier(params[:interface]) || host
        @subnet = Subnet.find(params[:subnet_id])
        @assigner = InterfaceAssigner.new(@deployment, @interface, @subnet)
        @assigner.unassign
        @errors[host.name] = @assigner.errors if @assigner.errors.present?
      end
      @destroyed = @errors.blank?
    end
  end
end
