require File.expand_path("spec_helper", File.dirname(__FILE__))

describe WeaselDiesel do

  before :all do
    @service = WSList.all.find{|s| s.url == 'services/test.xml'}
    @service.should_not be_nil
  end

  it "should have an url" do
    # dummy test since that's how we found the service, but oh well
    @service.url.should == 'services/test.xml'
  end

  it "should have some http verbs defined" do
    @service.verb.should == :get
  end

  it "should have supported formats defined" do
    @service.formats.should == [:xml, :json]
  end

  it "should have params info" do
    @service.params.should be_an_instance_of(WeaselDiesel::Params)
  end

  it "should have direct access to the required params" do
    @service.required_rules.should == @service.params.list_required
  end

  it "should have direct access to the optional params" do
    @service.optional_rules.should == @service.params.list_optional
  end

  it "should have direct access to the nested params" do
    @service.nested_params.should == @service.params.namespaced_params
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
      service = WSList["projects.xml"]
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

      service = WSList["project/:project_id/tasks.xml"]
      service.controller_dispatch("application").should == ["application", "project", "list"]

      service = WSList["project/:project_id/task/:task_id/items.xml"]
      service.controller_dispatch("application").should == ["application", "project", "list"]
    end

    it "should raise exception when controller class is not found" do
      describe_service("unknown.xml") do |service|
        service.controller_name = "UnknownController"
        service.action = "list"
      end
      service = WSList["unknown.xml"]
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
      @c_service = WSList.all.find{|s| s.url == 'services/test.xml'}
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
      service = WSList.all.find{|s| s.url == "services.xml"}
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
      service = WSList.all.find{|s| s.url == "players/:id.xml"}
      service.controller_name.should == "CustomController"
      service.action.should == "foo"
    end

  end


  describe WeaselDiesel::Params do

    before(:all) do
      @sparams = @service.params
    end

    it "should have the possibility to have a space name" do
      @sparams.should respond_to(:space_name)
      service_params = WeaselDiesel::Params.new(:space_name => 'spec_test')
      service_params.space_name.should == 'spec_test'
    end

    it "should have a list of required param rules" do
      @sparams.list_required.should be_an_instance_of(Array)
      @sparams.list_required.length.should == 1
    end

    it "should have a list of optional param rules" do
      @sparams.list_optional.should be_an_instance_of(Array)
      @sparams.list_optional.length.should == 4
    end

    it "should have a list of namespaced param rules" do
      @sparams.namespaced_params.should be_an_instance_of(Array)
      @sparams.namespaced_params.length.should == 1
      @sparams.namespaced_params.first.space_name.should == :user
    end

    it "should allow to define namespaced param" do
      service = WSList.all.find{|s| s.url == "services.xml"}
      service.params do |params|
        params.namespace :preference do |ns|
          ns.param :id, "Ze id."
        end
      end
      service.params.namespaced_params.should_not be_empty
      ns = service.params.namespaced_params.find{|ns| ns.space_name == :preference}
      ns.should_not be_nil
      ns.list_optional.first.name.should == "Ze id."
    end

    it "should allow object as an alias to namespaced param" do
      service = WSList.all.find{|s| s.url == "services.xml"}
      service.params do |params|
        params.object :preference do |ns|
          ns.param :id, "Ze id."
        end
      end
      service.params.namespaced_params.should_not be_empty
      ns = service.params.namespaced_params.find{|ns| ns.space_name == :preference}
      ns.should_not be_nil
      ns.list_optional.first.name.should == "Ze id."
    end

    describe WeaselDiesel::Params::Rule do
      before :all do
        @rule = @sparams.list_required.first
        @rule.should_not be_nil
      end

      it "should have a name" do
        @rule.name.should == :framework
      end

      it "should have options" do
        @rule.options[:type].should == :string
        @rule.options[:in].should ==  WeaselDieselSpecOptions
        @rule.options[:null].should be_false
      end
    end

  end

  it "should have some documentation" do
    @service.doc.should be_an_instance_of(WeaselDiesel::Documentation)
  end

  describe WeaselDiesel::Documentation do
    before(:all) do
      @doc = @service.doc
      @doc.should_not be_nil
    end

    it "should have an overall description" do
      @doc.desc.strip.should == "This is a test service used to test the framework."
    end

    it "should have a list of params doc" do
      @doc.params_doc.should be_an_instance_of(Hash)
      @doc.params_doc.keys.sort.should == [:framework, :version]
      @doc.params_doc[:framework].should == "The test framework used, could be one of the two following: #{WeaselDieselSpecOptions.join(", ")}."
    end

    it "should allow to define namespaced params doc" do
      service = WSList.all.find{|s| s.url == "services.xml"}
      service.documentation do |doc|
        doc.namespace :preference do |ns|
          ns.param :id, "Ze id."
        end
      end
      service.doc.namespaced_params.should_not be_empty
      ns = service.doc.namespaced_params.find{|ns| ns.name == :preference}
      ns.should_not be_nil
      ns.params[:id].should == "Ze id."
    end

    it "should allow object to be an alias for namespace params" do
      service = WSList.all.find{|s| s.url == "services.xml"}
      service.documentation do |doc|
        doc.object :preference do |ns|
          ns.param :id, "Ze id."
        end
      end
      service.doc.namespaced_params.should_not be_empty
      ns = service.doc.namespaced_params.find{|ns| ns.name == :preference}
      ns.should_not be_nil
      ns.params[:id].should == "Ze id."
    end

    it "should have an optional list of examples" do
      @doc.examples.should be_an_instance_of(Array)
      @doc.examples.first.should == <<-DOC
The most common way to use this service looks like that:
    http://example.com/services/test.xml?framework=rspec&version=2.0.0
      DOC
    end

    it "should have the service response documented" do
      @doc.response.should_not be_nil
    end

    it "should have documentation for the response elements via the response itself" do
      @service.response.elements.first.should_not be_nil
      @service.response.elements.first.doc.should_not be_nil
      @service.response.elements.first.doc.name.should == "player_creation_ratings"
    end

    it "should have documentation for a response element attribute" do
      p @service.response.elements.first.doc.inspect
      @service.response.elements.first.doc.attributes.should_not be_empty
      @service.response.elements.first.doc.attributes[:id].should == "id doc"
    end

    it "should have documentation for a response element array" do
      element = @service.response.elements.first
      element.arrays.should_not be_empty
      element.arrays.first.name.should == :player_creation_rating
      element.arrays.first.type.should == "PlayerCreationRating"
      element.arrays.first.attributes.should_not be_empty
    end

    it "should have documentation for the attributes of an response element array" do
      element = @service.response.elements.first
      array = element.arrays.first
      attribute = array.attributes.find{|att| att.name == :comments }
      attribute.should_not be_nil
      attribute.name.should == :comments # just in case we change the way to find the attribute
      attribute.doc.should == "comments doc"
    end

    it "should emit html documention for elements" do
      @service.response.elements.first.to_html.should be_a(String)
    end

  end
end
