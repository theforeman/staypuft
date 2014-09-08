module Staypuft
  class DeploymentsController < Staypuft::ApplicationController
    include Foreman::Controller::AutoCompleteSearch

    def index
      @deployments = Deployment.search_for(params[:search], :order => params[:order]).paginate(:page => params[:page]) || nil
    end

    def new
      deployment = Deployment.new(:name => Deployment::NEW_NAME_PREFIX+SecureRandom.hex)
      deployment.save!

      redirect_to deployment_steps_path(deployment_id: deployment)
    end

    def show
      @deployment = Deployment.find(params[:id])
      respond_to do | format |
        format.html {}
        format.json do
          render :status => 200, :json => @deployment.to_json(:methods => [:progress, :progress_summary])
        end
      end
    end

    def summary
      @deployment            = Deployment.find(params[:id])
      @service_hostgroup_map = @deployment.services_hostgroup_map
    end

    def update
      respond_to do | format |

        format.html do
          if params[:staypuft_deployment]
            param_data = params[:staypuft_deployment][:hostgroup_params]
            param_data.each do |hostgroup_id, hostgroup_params|
              hostgroup = Hostgroup.find(hostgroup_id)
              hostgroup_params[:puppetclass_params].each do |puppetclass_id, puppetclass_params|
                puppetclass = Puppetclass.find(puppetclass_id)
                puppetclass_params.each do |param_name, param_value|
                  hostgroup.set_param_value_if_changed(puppetclass, param_name, param_value)
                end
              end
            end
          end
          redirect_to "#{deployment_path(params[:id])}#advanced_configuration"
        end

        format.json do
          @deployment = Deployment.find(params[:id])
          @deployment.update_attributes(params[:deployment])
          render :status => 200, :json => @deployment.to_json
        end

      end
    end

    def edit
      @deployment            = Deployment.find(params[:id])
      @service_hostgroup_map = @deployment.services_hostgroup_map
    end

    def destroy
      Deployment.find(params[:id]).destroy
      process_success
    end

    def deploy
      deployment = Deployment.find(params[:id])
      task       = ForemanTasks.async_task ::Actions::Staypuft::Deployment::Deploy, deployment
      redirect_to deployment_path(deployment)
    end

    # TODO remove, it's temporary
    def populate
      task = ForemanTasks.async_task ::Actions::Staypuft::Deployment::Populate,
                                     Deployment.find(params[:id]),
                                     fake:   !!params[:fake],
                                     assign: !!params[:assign]
      redirect_to foreman_tasks_task_url(id: task)
    end

    def associate_host
      deployment             = Deployment.find(params[:id])
      hostgroup              = ::Hostgroup.find params[:hostgroup_id]
      deployment_in_progress = ForemanTasks::Lock.locked?(deployment, nil)

      hosts_to_assign = ::Host::Base.find Array(params[:host_ids])

      unassigned_hosts = hosts_to_assign.reduce([]) do |unassigned_hosts, discovered_host|
        success, host = assign_host_to_hostgroup discovered_host, hostgroup
        success ? unassigned_hosts : [*unassigned_hosts, host]
      end

      unless unassigned_hosts.empty?
        unassigned_messages = 'Unassigned hosts: <ul>' + unassigned_hosts.
                    map { |h| format '<li>%s <ul>%s</ul></li>', h.name_was, h.errors.full_messages.map {|msg|
                                     "<li>#{msg}</li>"}.join}.
                    join + '</ul>'

        flash[:error] = unassigned_messages
        Rails.logger.warn('Unassigned hosts:\n' + unassigned_hosts.
                    map { |h| format '%s (%s)', h.name_was, h.errors.full_messages.join(',') }.
                    join("\n") 
)
      end

      redirect_to deployment_path(deployment)
    end

    def unassign_host
      deployment             = Deployment.find(params[:id])
      deployment_in_progress = ForemanTasks::Lock.locked?(deployment, nil)

      hosts_to_unassign = ::Host::Base.find Array(params[:host_ids])

      removed_vips_hostgroup = nil
      hosts_to_unassign.each do |host|
        unless host.open_stack_deployed? && deployment_in_progress
          vip_interfaces = host.interfaces.vip
          removed_vips_hostgroup = host.hostgroup unless vip_interfaces.empty?
          vip_interfaces.each(&:destroy)
          host.open_stack_unassign
          host.environment = Environment.get_discovery
          host.save!
          host.setBuild
        end
      end
      if removed_vips_hostgroup
        removed_vips_hostgroup.reload
        newhost = removed_vips_hostgroup.hosts.first
        unless newhost.nil?
          build_vips_if_needed(newhost)
          newhost.save!
        end
      end

      redirect_to deployment_path(deployment)
    end

    def export_config
      @deployment = Deployment.find(params[:id])
      send_data DeploymentParamExporter.new(@deployment).to_hash.to_yaml,
                :type     => "application/x-yaml", :disposition => 'attachment',
                :filename => @deployment.name + '.yml'
    end

    def import_config
      @deployment = Deployment.find(params[:id])
      unless params[:deployment_config_file].nil?
        begin
          new_config = YAML.load_file(params[:deployment_config_file].path)
          DeploymentParamImporter.new(@deployment).import(new_config)

          flash[:notice] = "Updated parameter values"
        rescue Psych::SyntaxError => e
          flash[:error] = "Invalid input file: #{e}"
        rescue ArgumentError => e
          flash[:error] = "Invalid input file: #{e}"
        end
      else
        flash[:error] = "No import file specified"
      end
      redirect_to deployment_path(@deployment)
    end

    private

    def assign_host_to_hostgroup(discovered_host, hostgroup)
      converting_discovered = discovered_host.is_a? Host::Discovered

      if converting_discovered
        hosts_facts = FactValue.joins(:fact_name).where(host_id: discovered_host.id)
        discovery_bootif = hosts_facts.where(fact_names: { name: 'discovery_bootif' }).first or
            raise 'unknown discovery_bootif fact'

        interface = hosts_facts.
            includes(:fact_name).
            where(value: [discovery_bootif.value.upcase, discovery_bootif.value.downcase]).
            find { |v| v.fact_name.name =~ /^macaddress_.*$/ }.
            fact_name.name.split('_').last

        network = hosts_facts.where(fact_names: { name: "network_#{interface}" }).first
        hostgroup.subnet.network == network.value or
            raise "networks do not match: #{hostgroup.subnet.network} #{network.value}"
        ip = hosts_facts.where(fact_names: { name: "ipaddress_#{interface}" }).first
      end

      original_type = discovered_host.type
      host          = discovered_host.becomes(::Host::Managed)
      host.type     = 'Host::Managed'
      host.managed  = true
      host.build    = true
      host.ip       = ip.value if converting_discovered
      host.mac      = discovery_bootif.value if converting_discovered

      host.hostgroup   = hostgroup
      # set discovery environment to keep booting discovery image
      host.environment = Environment.get_discovery

      # root_pass is not copied for some reason
      host.root_pass   = hostgroup.root_pass

      # clear all virtual devices that may have been created during previous assignment
      host.clean_vlan_interfaces
      # by default foreman will try to manage all NICs unless user disables manually after assignment
      host.make_all_interfaces_managed

      # we create VIPs interfaces if this is the first host in Controller HA hostgroup
      build_vips_if_needed(host)

      # I do not why but the final save! adds following condytion to the update SQL command
      # "WHERE "hosts"."type" IN ('Host::Managed') AND "hosts"."id" = 283"
      # which will not find the record since it's still Host::Discovered.
      # Using #update_column to change it directly in DB
      # (discovered_host is used to avoid same WHERE condition problem here).
      # FIXME this is definitely ugly, needs to be properly fixed
      discovered_host.update_column :type, 'Host::Managed'

      [host.save, host].tap do |saved, _|
        discovered_host.becomes(Host::Base).update_column(:type, original_type) unless saved
      end
    end

    def build_vips_if_needed(host)
      hostgroup = host.hostgroup
      hostgroup.reload if hostgroup
      if hostgroup && hostgroup.deployment.ha? && (hostgroup == hostgroup.deployment.controller_hostgroup) && hostgroup.hosts.all? { |h| h.interfaces.vip.empty? }
        host.build_vips(Staypuft::NetworkQuery::VIP_NAMES)
      end
    end
  end

end
