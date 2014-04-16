module Staypuft
  class DeploymentsController < ApplicationController
    include Foreman::Controller::AutoCompleteSearch

    def index
      @deployments = Deployment.search_for(params[:search], :order => params[:order]).paginate(:page => params[:page]) || nil
    end

    def new
      if Deployment.first
        flash[:warning] = _('Deployment already exists.')
        redirect_to deployments_url
        return
      end

      base_hostgroup = Hostgroup.get_base_hostgroup

      deployment           = Deployment.new(:name => Deployment::NEW_NAME_PREFIX+SecureRandom.hex)
      deployment.layout    = Layout.where(:name       => "Distributed",
                                          :networking => "neutron").first
      deployment_hostgroup = ::Hostgroup.new name: deployment.name, parent: base_hostgroup
      deployment_hostgroup.save!

      deployment.hostgroup = deployment_hostgroup
      deployment.save!

      redirect_to deployment_steps_path
    end

    def show
      @deployment = Deployment.find(params[:id])
    end

    def summary
      @deployment = Deployment.find(params[:id])
      @services   = @deployment.services
    end

    def destroy
      Deployment.find(params[:id]).destroy
      process_success
    end

    def deploy
      task = ForemanTasks.async_task ::Actions::Staypuft::Deployment::Deploy, Deployment.first
      redirect_to foreman_tasks_task_url(id: task)
    end

    # TODO remove, it's temporary
    def populate
      task = ForemanTasks.async_task ::Actions::Staypuft::Deployment::Populate,
                                     Deployment.first,
                                     fake:   !!params[:fake],
                                     assign: !!params[:assign]
      redirect_to foreman_tasks_task_url(id: task)
    end

    def associate_host
      hostgroup = ::Hostgroup.find params[:hostgroup_id]

      targeted_hosts  = ::Host::Base.find Array(params[:host_ids])
      assigned_hosts  = hostgroup.hosts
      hosts_to_assign = targeted_hosts - assigned_hosts
      hosts_to_remove = assigned_hosts - targeted_hosts

      hosts_to_assign.each do |discovered_host|
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

        begin
          host.save!
        rescue => e
          discovered_host.update_column :type, original_type
          raise e
        end
      end

      hosts_to_remove.each do |host|
        host.hostgroup = nil
        host.save!
      end

      redirect_to deployment_path(id: ::Staypuft::Deployment.first)
    end
  end

end
