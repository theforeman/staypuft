module Staypuft
  module Concerns
    module HostOrchestrationBuildHook
      extend ActiveSupport::Concern

      included do
        before_provision :wake_up_orchestration
      end

      def wake_up_orchestration
        key = HostOrchestrationBuildHook.cache_id(id)
        ids = Rails.cache.read(key)
        Rails.cache.delete key
        ForemanTasks.dynflow.world.event *ids.values_at(:execution_plan_id, :step_id),
                                         installed_at: installed_at
      end

      def self.cache_id(host_id)
        "host.#{host_id}.wake_up_orchestration"
      end
    end
  end
end
