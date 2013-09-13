require 'rspec'
require 'rack/test'

require_relative "../lib/weasel_diesel"
require_relative 'test_services'
require_relative 'preferences_service'

ENV["RACK_ENV"] = 'test'

RSpec.configure do |conf|
  conf.include WeaselDiesel::DSL
  conf.include Rack::Test::Methods
end
