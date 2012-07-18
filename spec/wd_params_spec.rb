require File.expand_path("spec_helper", File.dirname(__FILE__))

describe WeaselDiesel::Params do

  before :all do
    @service = WSList.all.find{|s| s.url == 'services/test.xml'}
    @service.should_not be_nil
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
    @sparams.list_optional.length.should == 5
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
