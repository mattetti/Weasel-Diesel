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

    @third_service = describe_service "with_array" do |service|
      service.response do |response|
        response.array :users do |node|
          node.integer :id
          node.string  :name
          node.boolean :admin, :doc => "true if the user is an admin"
          node.string  :state, :doc => "test"
          node.datetime :last_login_at
        end
      end
    end

    @forth_service = describe_service "with_nested_array" do |service|
      service.response do |response|
        response.array :users do |node|
          node.integer :id
          node.string  :name
          node.boolean :admin, :doc => "true if the user is an admin"
          node.string  :state, :doc => "test"
          node.array :pets do |pet|
            pet.integer :id
            pet.string :name
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

  def valid_array_response
    {"users" => [
      {"id" => 1,
        "admin" => true,
        "state" => "retired",
        "last_login_at" => "2011-09-22T22:46:35-07:00"
      },
      {"id" => 2,
        "admin" => false,
        "state" => "playing",
        "last_login_at" => "2011-09-22T22:46:35-07:00"
      }]
    }
  end

  def valid_nested_array_response
    {"users" => [
      {"id" => 1,
        "admin" => true,
        "state" => "retired",
        "pets" => []
      },
      {"id" => 2,
        "admin" => false,
        "state" => "playing",
        "pets" => [{"id" => 23, "name" => "medor"}, {"id" => 34, "name" => "rex"}]
      }]
    }
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

  it "should validate array items" do
    valid, errors = @third_service.validate_hash_response(valid_array_response)
    valid.should be_true
    errors.should be_empty
  end

  it "should validate an empty array" do
    response = valid_array_response
    response["users"] = []
    valid, errors = @third_service.validate_hash_response(response)
    valid.should be_true
  end

  it "should catch error in an array item" do
    response = valid_array_response
    response["users"][1]["id"] = 'test'
    valid, errors = @third_service.validate_hash_response(response)
    valid.should be_false
    errors.should_not be_empty
  end

  it "should validate nested arrays" do
    valid, errors = @forth_service.validate_hash_response(valid_nested_array_response)
    valid.should be_true
  end

end
