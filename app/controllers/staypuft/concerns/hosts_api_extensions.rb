module Staypuft::Concerns::HostsApiExtensions
  extend ActiveSupport::Concern

  included do
    before_filter :check_openstack_hostgroup, only: [:create, :update]
  end

  def check_openstack_hostgroup
    if params[:host] and params[:host][:hostgroup_id]
      hostgroup_id = params[:host][:hostgroup_id]
      hg = Hostgroup.find(hostgroup_id)
      unless @host.deployment and @host.hostgroup == hg
        if hg.ancestors.include? Hostgroup.get_base_hostgroup
          Rails.logger.error "Cannot set a deployment hostgroup directly."
          render :json => {:error => _('Cannot set a deployment hostgroup directly.') }, :status => :forbidden
        end
      end
    end
  end
end
