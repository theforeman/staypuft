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
    module Deployment
      class Deploy < Actions::Base

        include Actions::Helpers::Lock
        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(deployment, hosts_to_deploy = nil, hosts_to_provision = nil)
          Type! deployment, ::Staypuft::Deployment

          input.update id: deployment.id, name: deployment.name
          plan_action Hostgroup::OrderedDeploy,
                      deployment.child_hostgroups.includes(:role).deploy_order.to_a,
                      hosts_to_deploy,
                      hosts_to_provision
          lock! deployment
        end

        def humanized_input
          input[:name]
        end

        def humanized_output
          planned_actions.first.humanized_output
        end

        def task_output
          planned_actions.first.task_output
        end

      end
    end
  end
end
