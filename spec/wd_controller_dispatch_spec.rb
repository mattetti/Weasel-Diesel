require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "WeaselDiesel #controller_dispatch" do

  before :all do
    @service = WSList.find(:get, '/services/test.xml')
    @service.should_not be_nil
  end

  describe "#controller_dispatch" do

    class ProjectsController
      def initialize(app, service)
        @app = app
        @service = service.name
      end

      def send(action)
        [@app, @service, action]
      end
    end

    module Projects
      class TasksController < ProjectsController
      end
    end

    module Projects
      module Tasks
        class ItemsController < ProjectsController
        end
      end
    end

    before :all do
      @original_use_controller_dispatch = WeaselDiesel.use_controller_dispatch
      WeaselDiesel.use_controller_dispatch = true
      @original_services = WSList.all.dup
      WSList.all.clear
    end

    after :all do
      WeaselDiesel.use_controller_dispatch = @original_use_controller_dispatch
      WSList.all.replace @original_services
    end

    it "should be able to dispatch controller" do
      describe_service("projects.xml") { |s| }
      service = WSList.find(:get, "projects.xml")
      service.controller_dispatch("application").
        should == ["application", "projects", "list"]
    end

    it "should be able to dispatch namespaced controller" do
      describe_service("project/:project_id/tasks.xml") do |service|
        service.controller_name = "Projects::TasksController"
        service.action = "list"
      end

      describe_service("project/:project_id/task/:task_id/items.xml") do |service|
        service.controller_name = "Projects::Tasks::ItemsController"
        service.action = "list"
      end

      service = WSList.find(:get, "project/:project_id/tasks.xml")
      service.controller_dispatch("application").should == ["application", "project", "list"]

      service = WSList.find(:get, "project/:project_id/task/:task_id/items.xml")
      service.controller_dispatch("application").should == ["application", "project", "list"]
    end

    it "should raise exception when controller class is not found" do
      describe_service("unknown.xml") do |service|
        service.controller_name = "UnknownController"
        service.action = "list"
      end
      service = WSList.find(:get, "unknown.xml")
      lambda { service.controller_dispatch("application") }.
        should raise_error("The UnknownController class was not found")
    end

  end

  describe "With controller dispatch on" do
    before :all do
      @original_services = WSList.all.dup
      WSList.all.clear
      WeaselDiesel.use_controller_dispatch = true
      load File.expand_path('test_services.rb', File.dirname(__FILE__))
      @c_service = WSList.find(:get, '/services/test.xml')
      @c_service.should_not be_nil
    end
    after :all do
      WeaselDiesel.use_controller_dispatch = false
      WSList.all.replace @original_services
    end

    it "should set the controller accordingly" do
      @c_service.controller_name.should_not be_nil
      @c_service.controller_name.should == 'ServicesController'
      service = WeaselDiesel.new("preferences.xml")
      service.name.should == 'preferences'
      ExtlibCopy.classify('preferences').should == 'Preferences'
      service.controller_name.should == 'PreferencesController'
    end

    it "should set the action accordingly" do
      @c_service.action.should_not be_nil
      @c_service.action.should == 'test'
    end

    it "should support restful routes based on the HTTP verb" do
      service = WSList.find(:put, "/services.xml")
      service.should_not be_nil
      service.http_verb.should == :put
      service.action.should_not be_nil
      service.controller_name.should == 'ServicesController'
      service.action.should == 'update'
    end

    it "should have a default action" do
      service = WeaselDiesel.new('spec_test.xml')
      service.action.should == 'list'
    end

    it "should route to show when an id is the last passed param" do
      service = WeaselDiesel.new("players/:id.xml")
      service.action.should == 'show'
    end

    it "should support some extra attributes" do
      service = WeaselDiesel.new("players/:id.xml")
      service.extra[:custom_name] = 'fooBar'
      service.extra[:custom_name].should == 'fooBar'
    end

    it "should respect the global controller pluralization flag" do
      WeaselDiesel.use_pluralized_controllers = true
      service = WeaselDiesel.new("player/:id.xml")
      service.controller_name.should == "PlayersController"
      service = WeaselDiesel.new("players/:id.xml")
      service.controller_name.should == "PlayersController"
      WeaselDiesel.use_pluralized_controllers = false
      service = WeaselDiesel.new("player/:id.xml")
      service.controller_name.should == "PlayerController"
    end


    it "should let overwrite the controller name and action after initialization" do
      describe_service "players/:id.xml" do |service|
        service.controller_name = "CustomController"
        service.action = "foo"
      end
      service = WSList.find(:get, "players/:id.xml")
      service.controller_name.should == "CustomController"
      service.action.should == "foo"
    end

  end

end
