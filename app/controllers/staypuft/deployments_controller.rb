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
      @hostgroup  = ::Hostgroup.find_by_id(params[:hostgroup_id]) ||
          @deployment.child_hostgroups.deploy_order.first
    end

    def summary
      @deployment            = Deployment.find(params[:id])
      @service_hostgroup_map = @deployment.services_hostgroup_map
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
      redirect_to foreman_tasks_task_url(id: task)
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

      hosts_to_assign  = ::Host::Base.find Array(params[:host_ids])

      unassigned_hosts = hosts_to_assign.reduce([]) do |unassigned_hosts, discovered_host|
        success, host = assign_host_to_hostgroup discovered_host, hostgroup
        success ? unassigned_hosts : [*unassigned_hosts, host]
      end

      unless unassigned_hosts.empty?
        flash[:warning] = 'Unassigned hosts: ' + unassigned_hosts.map(&:name_was).join(', ')
        Rails.logger.warn(
            "Unassigned hosts: \n" +
                unassigned_hosts.
                    map { |h| format '%s (%s)', h.name_was, h.errors.full_messages.join(',') }.
                    join("\n"))
      end

      redirect_to show_with_hostgroup_selected_deployment_path(
                      id: deployment, hostgroup_id: hostgroup)
    end

    def unassign_host
      deployment             = Deployment.find(params[:id])
      hostgroup              = ::Hostgroup.find params[:hostgroup_id]
      deployment_in_progress = ForemanTasks::Lock.locked?(deployment, nil)

      hosts_to_unassign  = ::Host::Base.find Array(params[:host_ids])

      hosts_to_unassign.each do |host|
        unless host.open_stack_deployed? && deployment_in_progress
          host.open_stack_unassign
          host.environment = Environment.get_discovery
          host.save!
          host.setBuild
        end
      end

      redirect_to show_with_hostgroup_selected_deployment_path(
                      id: deployment, hostgroup_id: hostgroup)
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
  end

end
