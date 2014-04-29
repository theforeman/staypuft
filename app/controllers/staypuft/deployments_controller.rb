module Staypuft
  class DeploymentsController < ApplicationController
    include Foreman::Controller::AutoCompleteSearch

    def index
      @deployments = Deployment.search_for(params[:search], :order => params[:order]).paginate(:page => params[:page]) || nil
    end

    def new
      base_hostgroup = Hostgroup.get_base_hostgroup

      deployment           = Deployment.new(:name => Deployment::NEW_NAME_PREFIX+SecureRandom.hex)
      deployment.layout    = Layout.where(:name       => "Distributed",
                                          :networking => "neutron").first
      deployment_hostgroup = ::Hostgroup.new name: deployment.name, parent: base_hostgroup
      deployment_hostgroup.save!

      deployment.hostgroup = deployment_hostgroup
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
      deployment = Deployment.find(params[:id])
      hostgroup  = ::Hostgroup.find params[:hostgroup_id]

      targeted_hosts  = ::Host::Base.find Array(params[:host_ids])
      assigned_hosts  = hostgroup.hosts
      hosts_to_assign = targeted_hosts - assigned_hosts
      hosts_to_remove = assigned_hosts - targeted_hosts

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

      hosts_to_remove.each do |host|
        host.hostgroup = nil
        host.save!
      end

      redirect_to show_with_hostgroup_selected_deployment_path(
                      id: deployment, hostgroup_id: hostgroup)
    end

    private

    def assign_host_to_hostgroup(discovered_host, hostgroup)
      original_type = discovered_host.type
      host          = discovered_host.becomes(::Host::Managed)
      host.type     = 'Host::Managed'
      host.managed  = true
      host.build    = true

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
