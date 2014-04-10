module Staypuft::Concerns::EnvironmentExtensions
  extend ActiveSupport::Concern

  module ClassMethods
    def get_discovery
      find_by_name('discovery') or
          raise ::Staypuft::Exception,
                'missing discovery environment, which ensures all its machines are booted ' +
                    'to discovery image.'
    end
  end
end
