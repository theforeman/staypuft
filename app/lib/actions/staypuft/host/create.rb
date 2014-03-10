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
      class Create < Dynflow::Action

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(name, hostgroup, compute_resource)
          # TODO: set action_subject
          # TODO: compute_resource or mac

          Type! hostgroup, Hostgroup
          Type! compute_resource, ComputeResource

          compute_attributes = hostgroup.
              compute_profile.
              compute_attributes.
              where(compute_resource_id: compute_resource.id).
              first.
              vm_attrs

          plan_self name:                name,
                    hostgroup_id:        hostgroup.id,
                    compute_resource_id: compute_resource.id,
                    compute_attributes:  compute_attributes
        end

        def run
          #noinspecti on RubyArgCount
          host = ::Host::Managed.new(
              name:                input[:name],
              hostgroup_id:        input[:hostgroup_id],
              compute_resource_id: input[:compute_resource_id],
              compute_attributes:  input[:compute_attributes].
                                       # for libvirt to start the machine, ugh, it has to be string
                                       merge(start: '1'),
              build:               true,
              managed:             true,
              enabled:             true,
              provision_method:    'build')
          host.save!
          output.update host_id: host.id

          # TODO suspend and wait for the provisioning to finish
        end

      end
    end
  end
end
