module Staypuft
  class InterfaceAssignmentsController < Staypuft::ApplicationController
    layout false
    def index
      @deployment = Deployment.find(params[:deployment_id])
      host_ids = params[:host_ids]
      host_ids = host_ids.split(',') unless host_ids.is_a? Array
      @hosts = Host::Managed.where(:id => host_ids).includes(:interfaces)
      @subnets = @deployment.subnets.uniq
      @host = @hosts.first
      @interfaces = @host ? @host.interfaces.where("type <> 'Nic::BMC'").non_vip.order(:identifier).physical : []

      errors = {}
      @hosts.each do |host|
        host_errors = compare(host, @host)
        errors[host.name] = host_errors.join(' and ') if host_errors.present?
      end

      if errors.present?
        flash[:error] = errors.map{ |k, v| "#{k}: #{v}" }.join('<br />')
        redirect_to deployment_path(@deployment)
      end
    end

    def create
      @errors = {}
      @deployment = Deployment.find(params[:deployment_id])
      host_ids = params[:host_ids]
      host_ids = host_ids.split(',') unless host_ids.is_a? Array
      @hosts = Host::Managed.where(:id => host_ids)
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
      host_ids = params[:host_ids]
      host_ids = host_ids.split(',') unless host_ids.is_a? Array
      @hosts = Host::Managed.where(:id => host_ids)
      @hosts.each do |host|
        @interface = host.interfaces.find_by_identifier(params[:interface]) || host
        @subnet = Subnet.find(params[:subnet_id])
        @assigner = InterfaceAssigner.new(@deployment, @interface, @subnet)
        @assigner.unassign
        @errors[host.name] = @assigner.errors if @assigner.errors.present?
      end
      @destroyed = @errors.blank?
    end

    private

    def compare(comparing, original)
      errors = []
      # primary interfaces, we don't check subnet_id since it's always PXE subnet
      if comparing.primary_interface != original.primary_interface
        errors.push _('does not have interfaces with same names')
        return errors
      end

      # other interfaces
      comparing = get_interfaces_to_compare(comparing)
      original = get_interfaces_to_compare(original)
      errors.push _('does not have same amount of interfaces') and return errors if comparing.size != original.size
      comparing.each do |interface|
        original_interface = original.select { |i| i.identifier == interface.identifier }.first
        errors.push _('does not have interfaces with same names') and return errors if original_interface.nil?
        errors.push _('has different subnet assignment on interface %s') % interface.identifier if interface.subnet_id != original_interface.subnet_id
      end
      errors
    end

    def get_interfaces_to_compare(host)
      host.interfaces.non_vip.where("type <> 'Nic::BMC'").order(:identifier)
    end
  end
end
