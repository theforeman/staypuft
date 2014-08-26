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
          host_list = hostgroup.hosts & hosts
          orchestration_mode = hostgroup.role.orchestration unless hostgroup.role.nil?

          case orchestration_mode
          when ::Staypuft::Role::ORCHESTRATION_CONCURRENT
            deploy_concurrently(host_list)
          when ::Staypuft::Role::ORCHESTRATION_SERIAL
            deploy_serially(host_list)
          when ::Staypuft::Role::ORCHESTRATION_LEADER
            deploy_leader_first(host_list)
          else
            deploy_concurrently(host_list)
          end
        end

        def deploy_concurrently(hosts)
          hosts.each do |host|
            # planned in concurrence
            plan_action Host::Deploy, host
          end
        end

        def deploy_serially(hosts)
          sequence do
            hosts.each do |host|
              plan_action Host::Deploy, host
            end
          end
        end

        def deploy_leader_first(hosts)
          first_host = hosts.shift
          sequence do
            #deploy first host, then deploy remainder in parallel
            plan_action Host::Deploy, first_host unless first_host.nil?
            concurrence do
              hosts.each do |host|
                plan_action Host::Deploy, host
              end
            end
          end
        end

        def humanized_input
          input[:name]
        end

        def task_output
          task_outputs = planned_actions.map(&:task_output)
          progress     = if task_outputs.size == 0
                           1
                         else
                           task_outputs.map { |to| to[:progress] }.reduce(&:+).to_f / task_outputs.size
                         end
          { id: input[:id], name: input[:name], progress: progress, hosts: task_outputs }
        end

        def humanized_output(task_output = self.task_output)
          format '%s %s%%', task_output[:name], (task_output[:progress]*100).to_i
        end

      end
    end
  end
end
