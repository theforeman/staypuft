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
      class Deploy < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(hostgroup, hosts)
          Type! hostgroup, ::Hostgroup
          (Type! hosts, Array).all? { |v| Type! v, ::Host::Base }

          input.update id: hostgroup.id, name: hostgroup.name

          # hostgroup.hosts returns already converted hosts from Host::Discovered with build flag
          # set to false so they are not built when assigned to the hostgroup in wizard
          # run Hostgroup's Hosts filtered by hosts
          (hostgroup.hosts & hosts).each do |host|
            # planned in concurrence
            plan_action Host::Deploy, host
          end
        end

        def humanized_input
          input[:name]
        end

        def humanized_output
          format "%s\n%s", input[:name],
                 planned_actions.map(&:humanized_output).map { |l| '  ' + l }.join("\n")
        end

      end
    end
  end
end
