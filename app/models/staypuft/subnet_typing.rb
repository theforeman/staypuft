module Staypuft
  class SubnetTyping < ActiveRecord::Base
    belongs_to :deployment
    belongs_to :subnet_type
    belongs_to :subnet

    attr_accessible :subnet_type, :subnet_type_id, :subnet, :subnet_id

    validate :one_subnet_per_type

    def one_subnet_per_type
      if self.class.
          where(:deployment_id => self.deployment_id,
                :subnet_type_id => self.subnet_type_id).
          where(['id <> ?', self.id]).any?
        errors.add :subnet_id
      end
    end

  end
end
