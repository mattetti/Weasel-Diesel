require File.expand_path("spec_helper", File.dirname(__FILE__))
require 'sinatra'
require File.expand_path("./../lib/framework_ext/sinatra.rb", File.dirname(__FILE__))
WeaselDiesel.send(:include, WeaselDieselSinatraExtension)

describe "Hello World example" do

    before :all do
      @original_use_controller_dispatch = WeaselDiesel.use_controller_dispatch
      WeaselDiesel.use_controller_dispatch = true
      @original_services = WSList.all.dup
      WSList.all.clear
      require "hello_world_service"
      require "hello_world_controller"
      @service = WSList.all.find{|s| s.url == 'hello_world.xml'}
      @service.should_not be_nil
      @service.load_sinatra_route
    end

    after :all do
      WeaselDiesel.use_controller_dispatch = @original_use_controller_dispatch
      WSList.all.replace @original_services
    end

    def app
      Sinatra::Application
    end

    it "should dispatch the hello world service properly" do
      @service.controller_name.should == "HelloWorldController"
      get "/hello_world.xml"
      last_response.body.should include("Hello World")
    end

end

