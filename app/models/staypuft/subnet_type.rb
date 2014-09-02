module Staypuft
  class SubnetType < ActiveRecord::Base
    PXE                = 'Provisioning/PXE'

    MANAGEMENT         = 'Management'
    EXTERNAL           = 'External'
    CLUSTER_MGMT       = 'Cluster Management'
    ADMIN_API          = 'Admin API'
    PUBLIC_API         = 'Public API'
    TENANT             = 'Tenant'

    STORAGE            = 'Storage'
    STORAGE_CLUSTERING = 'Storage Clustering'

    validates :name, :presence => true

    has_many :layout_subnet_types, :dependent => :destroy
    has_many :layouts, :through => :layout_subnet_types

    attr_accessible :name

    has_many :subnet_typings
    has_many :subnets, :through => :subnet_typings

    scope :required, lambda { where(:is_required => true) }
  end
end
