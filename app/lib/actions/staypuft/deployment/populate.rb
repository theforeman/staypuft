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

          fake = options[:fake].nil? ? false : options[:fake]
          Type! fake, TrueClass, FalseClass

          compute_resource = if fake
                               nil
                             else
                               options[:compute_resource] ||= ComputeResource.find_by_name!('Libvirt')
                             end
          Type! compute_resource, ComputeResource, NilClass


          sequence do
            plan_self deployment_id:       deployment.id,
                      deployment_name:     deployment.name,
                      fake:                fake

            hostgroups = deployment.child_hostgroups
            hostgroups.each do |hostgroup|
              plan_action Actions::Staypuft::Host::Create,
                          rand(1000).to_s,
                          hostgroup,
                          compute_resource,
                          start:  false,
                          assign: false,
                          fake:   fake
            end
          end
        end

        def run
          deployment = ::Staypuft::Deployment.find input.fetch(:deployment_id)
          hostgroups = deployment.child_hostgroups
          hostgroups.each do |hostgroup|
            hostgroup.hosts.each do |host|
              host.destroy # TODO make action for it
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
