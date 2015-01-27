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
      class TriggerProvisioning < Dynflow::Action

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(host)
          fail 'cannot provision unmanaged host' unless host.managed?

          sequence do
            # set the env to 'provisioning' to avoid compiling the
            # production catalog when actually not applying it, which
            # might cause errors
            plan_action Actions::Staypuft::Host::Update, host,
                        :environment_id => Environment.get_or_create_provisioning.id
            plan_self host_id: host.id
          end
        end

        def run
          host = ::Host.find(input[:host_id])
          host.expire_token
          host.set_token
          host.save!
          host.send :setTFTP
          restart host
        end

        private

        def restart(host)
          # always ignore power management for now, since the hosts are already out
          # of discovery env when it hits this code
          # TODO: figure out if we need to put the power management code back at some point
          restart_with_foreman_proxy host
        end

        def restart_with_foreman_proxy(host)
          host.setReboot
        end

        def restart_with_power_management(power)
          check_expected_state(power.state)
          if %w(running on).include?(power.state)
            unless power.reset
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
          unless %w(running on cycle shutoff off).include?(state.downcase)
            raise(::Staypuft::Exception, "Unexpected Host Power State: #{state}")
          end
        end
      end
    end
  end
end
