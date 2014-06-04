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
      # TODO remove, it's temporary
      class Populate < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(deployment, options = {})
          Type! deployment, ::Staypuft::Deployment

          fake   = options[:fake].nil? ? false : options[:fake]
          assign = options[:assign].nil? ? false : options[:assign]
          Type! fake, TrueClass, FalseClass

          compute_resource = options[:compute_resource] ||= ::Foreman::Model::Libvirt.first
          Type! compute_resource, *[ComputeResource, (NilClass if fake)].compact

          sequence do

            hostgroups = deployment.child_hostgroups
            hostgroups.each do |hostgroup|
              plan_action Actions::Staypuft::Host::Create,
                          "host-#{rand(1000).to_s}",
                          hostgroup,
                          compute_resource,
                          start:  false,
                          assign: assign,
                          fake:   fake
            end
          end
        end


        def humanized_input
          "#{input[:deployment_name]} #{input[:fake] ? 'fake' : 'real'}"
        end

      end
    end
  end
end
