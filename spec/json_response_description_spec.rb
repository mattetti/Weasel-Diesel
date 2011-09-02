require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "WSDSL JSON response description" do

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
          node.object :option do |node|
            node.integer :id
            node.integer :deal_id, :mock => 1
            node.float :price
          end
        end
      end
    end
  end

  it "should handle the json root node" do
    resp = @service.response
    root_node = resp.nodes.find{|n| n.name == :vouchers}
    root_node.should_not be_nil
  end

  it "should handle attributes of a node" do
    root_node = @service.response.nodes.find{|n| n.name == :vouchers}
    root_node.attributes.should_not be_empty
  end
  
end
