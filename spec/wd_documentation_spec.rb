require File.expand_path("spec_helper", File.dirname(__FILE__))

describe WeaselDiesel::Documentation do

  before :all do
    @service = WSList.all.find{|s| s.url == 'services/test.xml'}
    @service.should_not be_nil
    @doc = @service.doc
    @doc.should_not be_nil
  end

  it "should have an overall description" do
    @doc.desc.strip.should == "This is a test service used to test the framework."
  end

  it "should have a list of params doc" do
    @doc.params_doc.should be_an_instance_of(Hash)
    @doc.params_doc.keys.sort.should == [:framework, :num, :version]
    @doc.params_doc[:framework].should == "The test framework used, could be one of the two following: #{WeaselDieselSpecOptions.join(", ")}."
    @doc.params_doc[:num].should == 'The number to test'
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

  it "should have a json representation of an response element" do
    json = @service.response.elements.first.to_json
    loaded_json = JSON.load(json)
    loaded_json[@service.response.elements.first.doc.name].should_not be_empty
  end

  it "should have documentation for a response element attribute" do
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

  describe "legacy param documentation" do

    before :all do
      @original_services = WSList.all.dup
      WSList.all.clear
      define_service
    end

    after :all do
      WSList.all.replace @original_services
    end

    def define_service
      describe_service "legacy_param_doc" do |service|
        service.formats  :xml, :json

        service.params do |p|
          p.string :framework, :in => WeaselDieselSpecOptions, :null => false, :required => true

          p.datetime :timestamp, :default => Time.now
          p.string   :alpha,     :in      => ['a', 'b', 'c']
          p.string   :version,   :null    => false
          p.integer  :num,      :minvalue => 42

        end

        service.params.namespace :user do |user|
          user.integer :id, :required => :true
          user.string :sex, :in => %Q{female, male}
          user.boolean :mailing_list, :default => true
        end

        service.documentation do |doc|
          # doc.overall <markdown description text>
          doc.overall "This is a test service used to test the framework."
          # doc.params <name>, <definition>
          doc.param :framework, "The test framework used, could be one of the two following: #{WeaselDieselSpecOptions.join(", ")}."
          doc.param :version, "The version of the framework to use."
        end
      end
    end

    it "should have the param documented" do
      service = WSList["legacy_param_doc"]
      service.doc.params_doc.keys.sort.should == [:framework, :version]
      service.doc.params_doc[service.doc.params_doc.keys.first].should_not be_nil
    end

  end

end
