module Staypuft
  class DeploymentVipNic < ActiveRecord::Base
    attr_accessible :deployment, :deployment_id, :vip_nic, :vip_nic_id

    belongs_to :deployment
    belongs_to :vip_nic, dependent: :destroy

    validates :deployment, :presence => true
    validates :vip_nic, :presence => true
    validates :vip_nic_id, :uniqueness => true

  end
end
