if RUBY_VERSION =~ /1.8/
  require 'rubygems'
  require 'backports'
  require 'json'
end

require 'rspec'
require 'rack/test'
require 'sinatra'

require_relative "../lib/wsdsl"
require_relative 'test_services'
require_relative 'preferences_service'
require_relative "../lib/framework_ext/sinatra_controller"

ENV["RACK_ENV"] = 'test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end
