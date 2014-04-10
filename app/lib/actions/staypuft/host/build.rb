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
          host             = ::Host.find(input[:host_id])
          # return back to hostgroup's environment
          host.environment = nil
          host.save!
          host.send :setTFTP
          restart(host)
        end

        private

        def restart(host)
          power_management = begin
            host.power
          rescue Foreman::Exception => e
            if e.code == 'ERF42-9958' # Unknown power management support
              nil
            else
              raise e
            end
          end

          if power_management
            restart_with_power_management power_management
          else
            restart_with_foreman_proxy host
          end
        end

        def restart_with_foreman_proxy(host)
          host.setReboot # FIXME detect failures
        end

        def restart_with_power_management(power)
          check_expected_state(power.state)
          if %w(running on).include?(power.state)
            if !power.reset
              fail(::Staypuft::Exception, 'Resetting Host Failed')
            end
          end

          # FIXME host.power.reset leaves the host in "shutdown" state for
          # libvirt not tested in BMC. The following code makes sure the host starts again
          check_expected_state(power.state)
          if %w(shutoff off).include?(power.state)
            power.start or fail(::Staypuft::Exception, 'Starting Host Failed')
          end
        end

        def check_expected_state(state)
          if !%w(running on cycle shutoff off).include?(state.downcase)
            raise(::Staypuft::Exception, "Unexpected Host Power State: #{state}")
          end
        end
      end
    end
  end
end
