module Staypuft
  class VipNic < Nic::Managed
    has_one :deployment_vip_nic, :dependent => :destroy, :class_name => 'Staypuft::DeploymentVipNic'
    has_one :deployment, :class_name => 'Staypuft::Deployment', :through => :deployment_vip_nic

    before_save :reserve_ip

    # VIP nic is associated with the deployment, not the host
    def require_host?
      false
    end
    def reserve_ip
      if self.subnet.present? && self.subnet.ipam? && (!self.ip || self.subnet_id_changed?)
        self.ip = self.subnet.unused_ip
      end
    end
  end
end
