module Staypuft
  module Concerns
    module HostOrchestrationBuildHook
      extend ActiveSupport::Concern

      included do
        define_model_callbacks :built, :only => :after
        # TODO open Foreman PR and add a check to remove it after migration to Foreman 1.5
        after_commit :run_built_hooks
        after_built :wake_up_orchestration
      end

      def run_built_hooks
        if previous_changes[:build] == [true, false] && installed_at
          run_callbacks :built
        end
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
