module Staypuft
  module Concerns
    module HostOpenStackAffiliation
      extend ActiveSupport::Concern

      def open_stack_deployed?
        open_stack_assigned? &&
            respond_to?(:environment) &&
            environment != Environment.get_discovery
      end

      def open_stack_assigned?
        respond_to?(:hostgroup) &&
            hostgroup.try(:parent).try(:parent) == Hostgroup.get_base_hostgroup
      end

      def open_stack_unassign
        self.hostgroup = nil
        save!
      end
    end
  end
end
