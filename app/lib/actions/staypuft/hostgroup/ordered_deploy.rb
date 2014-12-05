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
      # deploys Hostgroups in given order
      class OrderedDeploy < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(hostgroups, hosts_to_deploy_filter, hosts_to_provision_filter)
          hosts_to_deploy_filter ||= hostgroups.
              map(&:hosts).
              reduce(&:+).
              select { |h| !h.open_stack_deployed? }

          hosts_to_provision_filter ||= hosts_to_deploy_filter.select(&:managed?)

          (Type! hostgroups, Array).all? { |v| Type! v, ::Hostgroup }
          (Type! hosts_to_deploy_filter, Array).all? { |v| Type! v, ::Host::Base }

          sequence do
            hosts              = hostgroups.map(&:hosts).reduce(&:+)
            hosts_to_provision = hosts & hosts_to_provision_filter
            hosts_to_deploy    = hosts & hosts_to_deploy_filter
            hosts_to_provision.each { |host| plan_action Host::TriggerProvisioning, host }

            concurrence do
              hosts_to_provision.each { |host| plan_action Host::WaitUntilProvisioned, host }
            end

            input.update hostgroups: {}
            hostgroups.each do |hostgroup|
              input[:hostgroups].update hostgroup.id => { name: hostgroup.name, hosts: {} }
              hostgroup_hosts = (hostgroup.hosts & hosts_to_deploy_filter)

              # wait till all hosts are ready
              concurrence do
                hostgroup_hosts.each do |host|
                  input[:hostgroups][hostgroup.id][:hosts].update host.id => host.name

                  plan_action Host::WaitUntilReady, host
                  plan_action Host::Update, host, :environment => nil
                end
              end

              # run puppet twice without checking for puppet success
              2.times do
                concurrence do
                  hostgroup_hosts.each do |host|
                    plan_action Host::Deploy, host, false
                  end
                end
              end

              # run puppet once and check it succeeded
              concurrence do
                hostgroup_hosts.each do |host|
                  plan_action Host::Deploy, host
                end
              end
            end

            enable_puppet_agent hosts_to_deploy
          end
        end

        def enable_puppet_agent(hosts)
          lookup_key_runmode_id = Puppetclass.
              find_by_name('foreman::puppet::agent::service').
              class_params.
              where(key: 'runmode').
              first.
              tap { |v| v || raise('missing runmode LookupKey') }.
              id

          sequence do
            hosts.each do |host|
              # enable puppet agent
              plan_action(Actions::Staypuft::Host::Update, host,
                          lookup_values_attributes:
                              { nil => { lookup_key_id: lookup_key_runmode_id,
                                         value:         'service' } })

            end
          end

          puppet_runs = sequence do
            hosts.map do |host|
              plan_action Actions::Staypuft::Host::PuppetRun, host
            end
          end

          concurrence do
            hosts.zip(puppet_runs).each do |host, puppet_run|
              sequence do
                plan_action Actions::Staypuft::Host::ReportWait, host.id, puppet_run.output[:executed_at]
                plan_action Actions::Staypuft::Host::AssertReportSuccess, host.id
              end
            end
          end
        end

        def humanized_input
          planned_actions.map(&:humanized_input).join(', ')
        end

        def humanized_output
          task_output.map { |hg| "#{hg[:name]} #{(hg[:progress]*100).to_i}%" }.join(', ')
        end

        def task_output
          steps          = all_planned_actions.map { |a| a.steps[1..2] }.reduce(&:+).compact
          stets_by_hosts = steps.inject({}) do |hash, step|
            key       = step.action(execution_plan).input[:host_id]
            hash[key] ||= []
            hash[key] << step
            hash
          end

          progresses_by_host = stets_by_hosts.inject({}) do |hash, (host_id, steps)|
            progress = if steps.empty?
                         'done'
                       else
                         total          = steps.map { |s| s.progress_done * s.progress_weight }.reduce(&:+)
                         weighted_count = steps.map(&:progress_weight).reduce(&:+)
                         total / weighted_count
                       end

            hash.update host_id => progress
          end

          (input[:hostgroups] || []).map do |hostgroup_id, hostgroup|
            next if hostgroup[:hosts].size == 0
            progress = hostgroup[:hosts].map { |id, _| progresses_by_host[id.to_i] }.sum.to_f / hostgroup[:hosts].size

            { id:       hostgroup_id,
              name:     hostgroup[:name],
              progress: progress,
              hosts:    hostgroup[:hosts].map do |id, name|
                { id: id, name: name, progress: progresses_by_host[id.to_i] }
              end }
          end.compact
        end
      end
    end
  end
end
