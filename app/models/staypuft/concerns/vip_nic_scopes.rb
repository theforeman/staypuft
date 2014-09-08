module Staypuft
  module Concerns
    module VipNicScopes
      extend ActiveSupport::Concern

      included do
        scope :vip, lambda { where(['identifier LIKE ?', 'vip%']) }
        scope :non_vip, lambda { where(['identifier NOT LIKE ?', 'vip%']) }
      end

    end
  end
end
