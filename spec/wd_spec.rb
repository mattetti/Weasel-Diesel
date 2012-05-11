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

  it "should have some documentation" do
    @service.doc.should be_an_instance_of(WeaselDiesel::Documentation)
  end

end
