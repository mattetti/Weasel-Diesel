require File.expand_path("spec_helper", File.dirname(__FILE__))
require File.expand_path("../lib/json_response_verification", File.dirname(__FILE__))

WSDSL.send(:include, JSONResponseVerification)

describe "JSON response verification" do

  before :all do
    @service = describe_service "json_response_verification" do |service|
      service.response do |response|
        response.element(:name => :user) do |user|
          user.integer :id
          user.string :name
          user.datetime :created_at
          user.object :creds do |creds|
            creds.integer :id
            creds.float   :price
            creds.boolean :enabled
          end
        end
      end
    end

    @second_service = describe_service "anonym_obj_json_response_verification" do |service|
      service.response do |response|
        response.object do |user|
          user.integer :id
          user.string :name
          user.datetime :created_at
          user.object :creds do |creds|
            creds.integer :id
            creds.float   :price
            creds.boolean :enabled
          end
        end
      end
    end

  end

  def valid_response(namespaced=true)
    response = { 
      "id" => 1, 
      "name" => "matt", 
      "created_at" => "2011-09-22T16:32:46-07:00", 
      "creds" => { "id" => 42, "price" => 2010.07, "enabled" => false }
      } 
    namespaced ? {"user" => response} : response
  end

  it "should validate the response" do
    valid, errors = @service.validate_hash_response(valid_response)
    valid.should be_true
    errors.should be_empty
  end

  it "should detect that the response is missing the top level object" do
    response = valid_response
    response.delete("user")
    valid, errors = @service.validate_hash_response(response)
    valid.should be_false
    errors.should_not be_empty
  end

  it "should detect that a property type is wrong" do
     response = valid_response
     response["user"]["id"] = 'test'
     valid, errors = @service.validate_hash_response(response)
     valid.should be_false
     errors.should_not be_empty
     errors.first.should match(/id/)
     errors.first.should match(/wrong type/)
  end

  it "should detect that a nested object is missing" do
     response = valid_response
     response["user"].delete("creds")
     valid, errors = @service.validate_hash_response(response)
     valid.should be_false
     errors.should_not be_empty
     errors.first.should match(/creds/)
     errors.first.should match(/missing/)
  end

  it "should validate non namespaced responses" do
    valid, errors = @second_service.validate_hash_response(valid_response(false))
    valid.should be_true
    errors.should be_empty
  end


end
