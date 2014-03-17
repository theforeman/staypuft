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
      class Build < Dynflow::Action

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(host_id)
          plan_self host_id: host_id
        end

        def run
          host = ::Host.find(input[:host_id])
          host.setBuild or fail(Staypuft::Exception, 'Setting Build Flag Failed')

          check_expected_state(host.power.state)
          if ['running', 'on'].include?(host.power.state)
            if !host.power.reset
              fail(::Staypuft::Exception, "Resetting Host Failed")
            end
          end

          # FIXME host.power.reset leaves the host in "shutdown" state for 
          # libvirt not tested in BMC.  The following code makes sure the host
          # starts again
          check_expected_state(host.power.state)
          if ['shutoff', 'off'].include?(host.power.state)
            host.power.start or fail(::Staypuft::Exception, "Starting Host Failed")
          end

        end

        private
        def check_expected_state(state)
          if !['running', 'on', 'cycle', 'shutdown', 'off'].include?(state.downcase)
            raise(::Staypuft::Exception, "Unexpected Host Power State: #{state}")
          end
        end
      end
    end
  end
end
