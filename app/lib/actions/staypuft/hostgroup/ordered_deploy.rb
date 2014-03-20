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
    module Hostgroup
      # deploys Hostgroups in given order
      class OrderedDeploy < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(hostgroups, hosts = hostgroups.inject([]) { |a, hg| a + hg.hosts })
          (Type! hostgroups, Array).all? { |v| Type! v, ::Hostgroup }
          (Type! hosts, Array).all? { |v| Type! v, ::Host::Base }

          sequence do
            hostgroups.each do |hostgroup|
              plan_action Hostgroup::Deploy, hostgroup, hosts
            end
          end
        end

        def humanized_input
          planned_actions.map(&:humanized_input).join(', ')
        end

        def humanized_output
          planned_actions.map(&:humanized_output).join("\n")
        end
      end
    end
  end
end
