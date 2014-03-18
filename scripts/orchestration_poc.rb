test_name        = ENV['TEST'] || 'simple'
compute_resource = ComputeResource.find_by_name!(ENV['COMPUTE_RESOURCE'] || 'Libvirt')
hostgroup1       = ::Hostgroup.find_by_name!(ENV['HOSTGROUP1'] || 'integration-test-1')
hostgroup2       = ::Hostgroup.find_by_name!(ENV['HOSTGROUP2'] || 'integration-test-2')
tests            = {}

tests['simple'] = lambda do |compute_resource, hostgroup, _hg|
  User.current = User.first

  result = ForemanTasks.trigger Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup, compute_resource
  raise result.error unless result.triggered?
  result.finished.value!

  result = ForemanTasks.trigger Actions::Staypuft::Hostgroup::OrderedDeploy, [hostgroup]
  raise result.error unless result.triggered?
  result.finished.value!
end

tests['complex'] = lambda do |compute_resource, hostgroup1, hostgroup2|
  User.current = User.first

  results = [ForemanTasks.trigger(Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup1, compute_resource,
                                  start: false),
             ForemanTasks.trigger(Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup2, compute_resource,
                                  start: false),
             ForemanTasks.trigger(Actions::Staypuft::Host::Create, "rhel#{rand 1000}", hostgroup2, compute_resource,
                                  start: false)]

  results.all? do |result|
    raise result.error unless result.triggered?
    result.finished.value!
  end

  result = ForemanTasks.trigger Actions::Staypuft::Hostgroup::OrderedDeploy, [hostgroup1, hostgroup2]
  raise result.error unless result.triggered?
  result.finished.value!
end

tests.fetch(test_name).call(compute_resource, hostgroup1, hostgroup2)
