require 'rubygems'
require 'benchmark/ips' # gem install benchmark_suite
$:<< '.'
require "../lib/params_verification"
require "../lib/weasel_diesel"
require "../spec/test_services"
require "old_exception_based_params_verification"

service = WSList.all.find{|s| s.url == 'services/test.xml'}
valid_params = {'framework' => 'RSpec', 'version' => '1.02', 'user' => {'id' => '123'}}
bad_params = {'framework' => 'minitest', 'version' => '1.02', 'user' => {'id' => '123'}}


ParamsVerification.validate(valid_params, service.defined_params)

Benchmark.ips do |x|
  # To reduce overhead, the number of iterations is passed in
  # and the block must run the code the specific number of times.
  # Used for when the workload is very small and any overhead
  # introduces incorrectable errors.
  x.report("new validation with valid params") do |times|
    i = 0
    while i < times
      ParamsVerification.validate(valid_params, service.defined_params)
      i += 1
    end
  end

  x.report("legacy validation with valid params") do |times|
    i = 0
    while i < times
      begin
        LegacyParamsVerification.validate!(valid_params, service.defined_params)
      rescue Exception => e
        p e
      end
      i += 1
    end
  end

  x.report("new validation with bad params") do |times|
    i = 0
    while i < times
      ParamsVerification.validate(bad_params, service.defined_params)
      i += 1
    end
  end

  x.report("legacy validation with bad params") do |times|
    i = 0
    while i < times
      begin
        LegacyParamsVerification.validate!(bad_params, service.defined_params)
      rescue Exception => e
        # e
      end
      i += 1
    end
  end

end
