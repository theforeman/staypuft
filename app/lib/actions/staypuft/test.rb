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
    def self.test(hostgroup = ::Hostgroup.find(15), compute_resource = ComputeResource.find(1))
      result = ForemanTasks.trigger Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup, compute_resource
      if result.is_a? Dynflow::World::Triggered
        result.finished.wait
        ForemanTasks.trigger Hostgroup::OrderedDeploy, [hostgroup]
      else
        raise result.error
      end
    end

    def self.test2(hostgroup1 = ::Hostgroup.find(15),
        hostgroup2 = ::Hostgroup.find(16),
        compute_resource = ComputeResource.find(1))

      results = [ForemanTasks.trigger(Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup1, compute_resource,
                                      start: false),
                 ForemanTasks.trigger(Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup2, compute_resource,
                                      start: false),
                 ForemanTasks.trigger(Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup2, compute_resource,
                                      start: false)]

      results.all? do |result|
        if result.is_a? Dynflow::World::Triggered
          result.finished.wait
        else
          raise result.error
        end
      end

      ForemanTasks.trigger Hostgroup::OrderedDeploy, [hostgroup1, hostgroup2]
    end
  end
end
