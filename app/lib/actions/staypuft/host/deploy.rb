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
      class Deploy < Actions::Base

        def plan(host)
          Type! host, ::Host::Base

          input.update host: { id: host.id, name: host.name }

          unless host.open_stack_deployed?
            sequence do
              plan_action Host::Build, host.id
              plan_action Host::WaitUntilInstalled, host.id
              plan_action Host::WaitUntilHostReady, host.id
            end
          else
            # it is already deployed
          end
        end

        def humanized_output
          # TODO: use Action::Progress.calculate in new dynflow version
          steps    = planned_actions.inject([]) { |s, a| s + a.steps[1..2] }.compact
          progress = if steps.empty?
                       'done'
                     else
                       total          = steps.map { |s| s.progress_done * s.progress_weight }.reduce(&:+)
                       weighted_count = steps.map(&:progress_weight).reduce(&:+)
                       format '%3d%%', total / weighted_count * 100
                     end
          format '%s Host: %s', progress, input[:host][:name]
        end

      end
    end
  end
end
