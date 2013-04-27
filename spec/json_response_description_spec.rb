require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "WeaselDiesel JSON response description" do

# JSON response example
=begin
  { vouchers: [ 
  { 
    id : 1, 
    redeemed : false,
    created_at : 123123123123, 
    option: {
      id : 1231,
      price: 123.32
    }
  }, 
  { 
    id : 2, 
    redeemed : true,
    created_at : 123123123123, 
    option: {
      id : 1233,
      price: 1.32
    }
  }, 
] }
=end

  before :all do
    @timestamp = Time.now.to_i
    @service =  describe_service "json_list" do |service|
      service.formats  :json
      service.response do |response|
        response.array :vouchers do |node|
          node.key :id
          node.type :Voucher
          node.string :name, :mock => "test"
          node.integer :id, :doc => "Identifier"
          node.boolean :redeemed
          node.datetime :created_at, :mock => @timestamp
          node.object :option do |option|
            option.integer :id
            option.integer :deal_id, :mock => 1
            option.float :price
          end
        end
      end
    end
    @response  = @service.response
    @root_node = @response.nodes.find{|n| n.name == :vouchers}

  end

  it "should handle the json root node" do
    @root_node.should_not be_nil
  end

  it "should handle a node property list" do
    props = @root_node.properties
    props.should_not be_empty
    {:id => :integer, :redeemed => :boolean, :created_at => :datetime}.each do |key, type|
      prop = props.find{|prop| prop.name == key}
      prop.should_not be_nil
      prop.type.should == type
    end
  end

  it "should handle a nested object with properties" do
    @root_node.objects.should_not be_nil
    option = @root_node.objects.find{|o| o.name == :option}
    option.should_not be_nil
    {:id => :integer, :deal_id => :integer, :price => :float}.each do |key, type|
      prop = option.properties.find{|prop| prop.name == key}
      if prop.nil?
        puts option.properties.inspect
        puts [key, type].inspect
      end
      prop.should_not be_nil
      prop.type.should == type
    end
  end

  it "should allow some meta attributes" do
    atts = @root_node.meta_attributes
    atts.should_not be_nil
    {:key => :id, :type => :Voucher}.each do |type, value|
      meta = atts.find{|att| att.type == type}
      puts [type, atts].inspect if meta.nil?
      meta.should_not be_nil
      meta.value.should == value
    end
    @root_node.key.should == :id
    @root_node.type.should == :Voucher
  end

  it "should handle mocked values properly" do
    created_at = @root_node.properties.find{|prop| prop.name == :created_at}
    created_at.opts[:mock].should == @timestamp
    option = @root_node.objects.find{|prop| prop.name == :option}
    deal_id = option.properties.find{|prop| prop.name == :deal_id}
    deal_id.opts[:mock].should == 1
    name = @root_node.properties.find{|prop| prop.name == :name}
    name.opts[:mock].should == "test"
  end

  it "should allow an anonymous object at the root of the response" do
    service =  describe_service "json_anonymous_obj" do |service|
      service.formats  :json
      service.response do |response|
        response.object do |obj|
          obj.integer :id
          obj.string :foo
        end
      end
    end
    response = service.response
    response.nodes.should_not be_empty
    obj = response.nodes.first
    obj.should_not be_nil
    obj.properties.find{|prop| prop.name == :id}.should_not be_nil
    obj.properties.find{|prop| prop.name == :foo}.should_not be_nil
  end
  
end



describe "WeaselDiesel simple JSON object response description" do

# JSON response example
=begin
  {"organization": {"name": "Example"}}
=end

  before :all do
    @timestamp = Time.now.to_i
    @service =  describe_service "json_obj" do |service|
      service.formats  :json
      service.response do |response|
        response.object :organization do |node|
          node.string :name
        end
      end
    end
    @response  = @service.response
  end

  it "should have a properly structured reponse" do
    top_object = @service.response.element_named(:organization)
    top_object.should_not be_nil
    name_node = top_object.properties.find{|o| o.name == :name}
    name_node.should_not be_nil
    name_node.type.should == :string
  end

end


describe "WeaselDiesel anonymous JSON object response description" do

# JSON response example
=begin
  {"name": "Example"}
=end

  before :all do
    @timestamp = Time.now.to_i
    @service =  describe_service "anon_json_obj" do |service|
      service.formats  :json
      service.response do |response|
        response.object do |node|
          node.string :name
        end
      end
    end
    @response  = @service.response
  end

  it "should have a properly structured response" do
    top_object = @service.response.elements.first
    top_object.should_not be_nil
    name_node = top_object.properties.find{|o| o.name == :name}
    name_node.should_not be_nil
    name_node.type.should == :string
  end

end


describe "WeaselDiesel top level array response description" do

=begin
'[ { "name":"Bob" }, { "name": "Judy" } ]'
=end

  before :all do
    @service = describe_service 'tl_array' do |service|
      service.formats :json
      service.response do |response|
        # anonymous array response
        response.array do |arr|
          arr.object do |node|
            node.string :name
          end
        end
      end
    end
  end

  it "should have a properly structured response" do
    top_object = @service.response.nodes.first
    top_object.should_not be_nil
    top_object.should be_an_instance_of(WeaselDiesel::Response::Vector)
    top_object.elements.first.should_not be_nil
    top_object.elements.first.attributes.first.name.should eq(:name)
    top_object.elements.first.attributes.first.type.should eq(:string)
  end

end
