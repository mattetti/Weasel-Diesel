require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "WSDSL JSON response description" do

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
    @service =  describe_service "json_list" do |service|
      service.formats  :json
      service.response do |response|
        response.array :vouchers do |node|
          node.key :id
          node.type :Voucher
          node.integer :id, :doc => "Identifier"
          node.boolean :redeemed
          node.datetime :created_at
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
  
end
