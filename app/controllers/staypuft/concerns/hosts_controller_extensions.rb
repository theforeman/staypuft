module Staypuft::Concerns::HostsControllerExtensions
  extend ActiveSupport::Concern

  included do
    before_filter :check_openstack_hostgroup, only: [:create, :update]
    before_filter :check_openstack_hostgroup_multiple, only: [:update_multiple_hostgroup]
  end

  def check_openstack_hostgroup
    if params[:host] and params[:host][:hostgroup_id]
      hostgroup_id = params[:host][:hostgroup_id]
      hostgroup = Hostgroup.find(hostgroup_id)
      unless hostgroup.deployment and @host.hostgroup == hostgroup
        if openstack_hostgroup? hostgroup_id
          Rails.logger.error "Cannot set a deployment hostgroup directly."
          error _('Invalid host group selected! Cannot select OpenStack deployment host group.')
          render :action => :edit and return
        end
      end
    end
  end

  def check_openstack_hostgroup_multiple
    if params["hostgroup"] and params["hostgroup"]["id"]
      hostgroup_id = params["hostgroup"]["id"]
      if openstack_hostgroup? hostgroup_id
        error _('Invalid host group selected! Cannot select OpenStack deployment host group.')
        redirect_to(select_multiple_hostgroup_hosts_path) and return
      end
    end
  end

  private

  def openstack_hostgroup?(id)
    hg = Hostgroup.find(id)
    hg.ancestors.include? Hostgroup.get_base_hostgroup
  rescue
    false
  end
end
