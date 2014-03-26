module Staypuft::Concerns::PuppetclassExtensions
  extend ActiveSupport::Concern

  included do
    has_many :role_classes, :dependent => :destroy, :class_name => 'Staypuft::RoleClass'
    has_many :roles, :through => :role_classes, :class_name => 'Staypuft::Role'

    has_many :service_classes, :dependent => :destroy, :class_name => 'Staypuft::ServiceClass'
    has_many :services, :through => :service_classes, :class_name => 'Staypuft::Service'

  end
end
