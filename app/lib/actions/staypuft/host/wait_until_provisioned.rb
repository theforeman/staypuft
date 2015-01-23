#
# Copyright 2014 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

module Actions
  module Staypuft
    module Host

      class WaitUntilProvisioned < Actions::Base

        TIMEOUT = 7200

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser
        # Using the Timeout middleware to make sure input[:timeout] is
        # set. The actual timeout check is performed separately for
        # the WaitUntilProvisioned because it's not a polling action.
        middleware.use Actions::Staypuft::Middleware::Timeout

        def plan(host)
          plan_self host_id: host.id
        end

        def run(event = nil)
          case event
          when nil
            suspend do |suspended_action|
              # schedule timeout
              world.clock.ping suspended_action, input[:timeout], "timeout"

              # wake up when provisioning is finished
              Rails.cache.write(
                  ::Staypuft::Concerns::HostOrchestrationBuildHook.cache_id(input[:host_id]),
                  { execution_plan_id: suspended_action.execution_plan_id,
                    step_id:           suspended_action.step_id })
            end
          when "timeout"
            # clear timeout_start so that the action can be resumed/skipped
            output[:timeout_start] = nil
            fail(::Staypuft::Exception,
                 "You've reached the timeout set for this action. If the " +
                 "action is still ongoing, you can click on the " +
                 "\"Resume Deployment\" button to continue.")
          when Hash
            output[:installed_at] = event.fetch(:installed_at).to_s
          when Dynflow::Action::Skip
            output[:installed_at] = Time.now.utc.to_s
          else
            raise TypeError
          end
        end

        def run_progress_weight
          4
        end

        def run_progress
          0.1
        end

      end
    end
  end
end
