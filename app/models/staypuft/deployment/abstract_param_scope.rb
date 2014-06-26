module Staypuft
  class Deployment::AbstractParamScope
    include ActiveModel::Validations
    extend ActiveModel::Callbacks
    extend Deployment::AttributeParamStorage
    define_model_callbacks :save, :only => [:after]

    def self.param_scope
      raise NotImplementedError
    end

    attr_reader :deployment

    def initialize(deployment)
      @deployment = deployment
    end

    def hostgroup
      deployment.hostgroup
    end

    # compatibility with validates_associated
    def marked_for_destruction?
      false
    end

    def attributes=(attr_list)
      attr_list.each { |attr, value| send "#{attr}=", value } unless attr_list.nil?
    end
  end
end
