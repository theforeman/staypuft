module Staypuft::Concerns::EnvironmentExtensions
  extend ActiveSupport::Concern

  module ClassMethods
    def get_discovery
      find_by_name('discovery') or raise ::Staypuft::Exception, 'missing discovery environment'
    end
  end
end
