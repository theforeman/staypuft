module Staypuft
  class SubnetTyping < ActiveRecord::Base
    belongs_to :deployment
    belongs_to :subnet_type
    belongs_to :subnet

    attr_accessible :subnet_type, :subnet_type_id, :subnet, :subnet_id

    validates :subnet_type_id, :uniqueness => { :scope => :deployment_id }
  end
end
