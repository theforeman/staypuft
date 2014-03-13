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
      class Create < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(name, hostgroup, compute_resource, options = {})
          # TODO: set action_subject
          # TODO: compute_resource or mac

          Type! hostgroup, ::Hostgroup
          Type! compute_resource, ComputeResource

          compute_attributes = hostgroup.
              compute_profile.
              compute_attributes.
              where(compute_resource_id: compute_resource.id).
              first.
              vm_attrs

          options = { :start => true }.merge options

          plan_self name:                name,
                    hostgroup_id:        hostgroup.id,
                    compute_resource_id: compute_resource.id,
                    compute_attributes:  compute_attributes,
                    options:             options

        end

        def run
          #noinspecti on RubyArgCount
          host = ::Host::Managed.new(
              name:                input[:name],
              hostgroup_id:        input[:hostgroup_id],
              compute_resource_id: input[:compute_resource_id],
              compute_attributes:  input[:compute_attributes],
              build:               false,
              managed:             true,
              enabled:             true)
          host.save!
          host.power.start if input[:options][:start]
          output.update host: { id:   host.id,
                                name: host.name,
                                ip:   host.ip,
                                mac:  host.mac }
        end

        def humanized_input
          input[:name]
        end

      end
    end
  end
end
