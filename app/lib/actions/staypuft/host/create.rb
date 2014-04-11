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
          Type! hostgroup, ::Hostgroup
          Type! compute_resource, ComputeResource, NilClass

          options = { start: true, assign: true, fake: false }.merge options

          compute_attributes = if options[:fake]
                                 {}
                               else
                                 hostgroup.
                                     compute_profile.
                                     compute_attributes.
                                     where(compute_resource_id: compute_resource.id).
                                     first.
                                     vm_attrs
                               end


          plan_self name:               name,
                    hostgroup_id:       hostgroup.id,
                    compute_attributes: compute_attributes,
                    options:            options
          input.update compute_resource_id: compute_resource.id if compute_resource
        end

        def run
          fake   = input.fetch(:options).fetch(:fake)
          assign = input.fetch(:options).fetch(:assign)

          host = if fake
                   raise if assign
                   ::Host::Managed.new(
                       name:         input[:name],
                       hostgroup_id: input[:hostgroup_id],
                       build:        true,
                       managed:      true,
                       enabled:      true,
                       environment:  Environment.get_discovery,
                       mac:          '0a:' + Array.new(5).map { format '%0.2X', rand(256) }.join(':'))
                 else
                   ::Host::Managed.new(
                       name:                input[:name],
                       hostgroup_id:        input[:hostgroup_id],
                       build:               true,
                       managed:             true,
                       enabled:             true,
                       environment:         Environment.get_discovery,
                       compute_resource_id: input.fetch(:compute_resource_id),
                       compute_attributes:  input[:compute_attributes])
                 end

          host.save!
          host.power.start if input.fetch(:options).fetch(:start)

          unless assign
            host.reload
            host.hostgroup = nil
            host.save!
          end

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
