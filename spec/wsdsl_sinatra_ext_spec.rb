require File.expand_path("spec_helper", File.dirname(__FILE__))
require 'sinatra'
require File.expand_path("./../lib/framework_ext/sinatra.rb", File.dirname(__FILE__))
WSDSL.send(:include, WSDSLSinatraExtension)

describe "Hello World example" do
    require_relative "hello_world_service"
    require_relative "hello_world_controller"

    def app
      Sinatra::Application
    end

    before(:all) do
      service = WSList.all.find{|s| s.url == 'hello_world.xml'}
      service.should_not be_nil
      service.load_sinatra_route
    end

    it "should dispatch the hello world service properly" do
      get "/hello_world.xml"
      last_response.body.should include("Hello World")
    end

end

