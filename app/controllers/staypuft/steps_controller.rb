module Staypuft
  class StepsController < Staypuft::ApplicationController
    include Wicked::Wizard
    steps :deployment_settings, :network_configuration, :services_overview, :services_configuration

    before_filter :get_deployment

    def show
      case step
      when :deployment_settings
        @layouts = ordered_layouts
      when :services_overview
        if !@deployment.ha? && @deployment.cinder.lvm_ptable.nil?
          flash[:warning] = "Missing Partition Table 'LVM with cinder-volumes', LVM cinder backend won't work." 
        end
      when :network_configuration
        @subnets = Subnet.search_for(params[:search], :order => params[:order]).includes(:domains, :dhcp).paginate :page => params[:page]
      when :services_configuration
        @services_map = [:nova, :neutron, :glance, :cinder]
      end

      render_wizard
    end

    def update
      case step

      when :deployment_settings
        @layouts               = ordered_layouts
        # FIXME: validate that deployment is valid when leaving wizard with cancel button
        @deployment.form_step  = Deployment::STEP_SETTINGS
        @deployment.passwords.attributes = params[:staypuft_deployment].delete(:passwords)
        @deployment.attributes = params[:staypuft_deployment]

        # we don't care too much whether pxe network was detected or all typings were saved since it's
        # just a helper for user to have all types preassigned to pxe network
        pxe_network = Subnet.where('dhcp_id IS NOT NULL').first
        if pxe_network
          @deployment.unassigned_pxe_default_subnet_types.each do |type|
            @deployment.subnet_typings.new(:subnet_id => pxe_network.id, :subnet_type_id => type.id).save
          end
        end

      when :services_overview
        @deployment.form_step = Deployment::STEP_OVERVIEW

      when :services_configuration
        @services_map = [:nova, :neutron, :glance, :cinder]
        if params[:staypuft_deployment]
          @deployment.form_step = Deployment::STEP_CONFIGURATION
          @services_map.each do |service|
            @deployment.send(service).attributes = params[:staypuft_deployment].delete(service)
          end
        end
      when :network_configuration
        @deployment.form_step = Deployment::STEP_NETWORKING
        @subnets = Subnet.search_for(params[:search], :order => params[:order]).includes(:domains, :dhcp).paginate :page => params[:page]
        @deployment.build_vips(NetworkQuery::VIP_NAMES) if @deployment.valid?
      else
        raise 'unknown step'
      end

      render_wizard @deployment
    end

    private
    def get_deployment
      @deployment      = Deployment.find(params[:deployment_id])
      @deployment.name = nil if @deployment.name.starts_with?(Deployment::NEW_NAME_PREFIX)
    end

    def redirect_to_finish_wizard(options = {})
      redirect_to deployment_path(@deployment), :notice => _("Deployment has been succesfully configured.")
    end

    def ordered_layouts
      Layout.order(:name).order("networking DESC").all
    end
  end
end
