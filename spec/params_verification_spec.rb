require_relative "spec_helper"

describe ParamsVerification do

  before :all do
    @service = WSList.find(:get, '/services/test.xml')
    @service.should_not be_nil
    @valid_params = {'framework' => 'RSpec', 'version' => '1.02', 'options' => nil, 'user' => {'id' => '123', 'groups' => 'manager,developer', 'skills' => 'java,ruby'}}
  end

  def copy(params)
    Marshal.load( Marshal.dump(params) )
  end

  it "should validate valid params" do
    params = copy(@valid_params)
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should_not raise_exception
    params['name'] = 'Mattetti'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should_not raise_exception
  end

  it "should return the params" do
    params = copy(@valid_params)
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params.should be_an_instance_of(Hash)
    returned_params.keys.size.should >= 3
  end

  it "shouldn't set empty nil values for optional params that aren't passed" do
    params = copy(@valid_params)
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params.has_key?('name').should be_false
  end

  it "should return array in the params" do
    params = copy(@valid_params)
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params['user']['groups'].should be == @valid_params['user']['groups'].split(",")
    returned_params['user']['skills'].should be == @valid_params['user']['skills'].split(",")
  end

  it "should not duplicate params in the root level" do
    params = copy(@valid_params)
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params['groups'].should be_nil
    returned_params['skills'].should be_nil
  end

  it "should raise an exception when values of required param are not in the allowed list" do
    params = copy(@valid_params)
    params['user']['groups'] = 'admin,root,manager'
    lambda { ParamsVerification.validate!(params, @service.defined_params) }.should raise_error(ParamsVerification::InvalidParamValue)
  end

  it "should raise an exception when values of optional param are not in the allowed list" do
    params = copy(@valid_params)
    params['user']['skills'] = 'ruby,java,php'
    lambda { ParamsVerification.validate!(params, @service.defined_params) }.should raise_error(ParamsVerification::InvalidParamValue)
  end

  it "should set the default value for an optional param" do
    params = copy(@valid_params)
    params['timestamp'].should be_nil
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params['timestamp'].should_not be_nil
  end

  it "should support various datetime formats" do
    params = copy(@valid_params)
    params['timestamp'] = Time.now.iso8601
    lambda { ParamsVerification.validate!(params, @service.defined_params) }.should_not raise_error
    params['timestamp'] = Time.now.getutc.iso8601
    lambda { ParamsVerification.validate!(params, @service.defined_params) }.should_not raise_error(ParamsVerification::InvalidParamType)
  end

  it "should set the default value for a namespace optional param" do
    params = copy(@valid_params)
    params['user']['mailing_list'].should be_nil
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params['user']['mailing_list'].should be_true
  end

  it "should verify child param rules if namespace is not null, but it nullable" do
    params = copy(@valid_params)
    params['options'] = {'verbose' => 'true'}
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params['options']['verbose'].should be_true
  end

  it "should skip child param rules if namespace is null" do
    params = copy(@valid_params)
    params['options'].should be_nil
    returned_params = ParamsVerification.validate!(params, @service.defined_params)
    returned_params['options'].should be_nil
  end

  it "should raise an exception when a required param is missing" do
    params = copy(@valid_params)
    params.delete('framework')
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::MissingParam)
  end

  it "should cast a comma delimited string into an array when param marked as an array" do
    service = WSList.find(:post, "/services/array_param.xml")
    service.should_not be_nil
    params = {'seq' => "a,b,c,d,e,g"}
    validated = ParamsVerification.validate!(params, service.defined_params)
    validated['seq'].should == %W{a b c d e g}
  end

  it "should not raise an exception if a req array param doesn't contain a comma" do
    service = WSList.find(:post, "/services/array_param.xml")
    params = {'seq' => "a b c d e g"}
    lambda{ ParamsVerification.validate!(params, service.defined_params) }.should_not raise_exception(ParamsVerification::InvalidParamType)
  end

  it "should raise an exception when a param is of the wrong type" do
    params = copy(@valid_params)
    params['user']['id'] = 'abc'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamType)
  end

  it "should raise an exception when a param is under the min_value" do
    params = copy(@valid_params)
    params['num'] = '1'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
    params['num'] = 1
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should raise an exception when a param is over the max_value" do
    params = copy(@valid_params)
    params['num'] = 10_000
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should raise an exception when a param is under the min_length" do
    params = copy(@valid_params)
    params['name'] ='bob'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should raise an exception when a param is over the max_length" do
    params = copy(@valid_params)
    params['name'] = "Whether 'tis nobler in the mind to suffer The slings and arrows of outrageous fortune"
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should raise an exception when a param isn't in the param option list" do
    params = copy(@valid_params)
    params['alpha'] = 'z'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should raise an exception when a nested optional param isn't in the param option list" do
    params = copy(@valid_params)
    params['user']['sex'] = 'large'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
    # other service
    params = {'preference' => {'region_code' => 'us', 'language_code' => 'de'}}
    service = WSList.find(:get, '/preferences.xml')
    service.should_not be_nil
    lambda{ ParamsVerification.validate!(params, service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should raise an exception when a required param is present but doesn't match the limited set of options" do
    service = describe_service "search" do |service|
      service.params { |p| p.string :by, :options => ['name', 'code', 'last_four'], :required => true }
    end
    params = {'by' => 'foo'}
    lambda{ ParamsVerification.validate!(params, service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should validate that no params are passed when accept_no_params! is set on a service" do
    service = WSList.find(:get, "/services/test_no_params.xml")
    service.should_not be_nil
    params = copy(@valid_params)
    lambda{ ParamsVerification.validate!(params, service.defined_params) }.should raise_exception
  end

  it "should raise an exception when an unexpected param is found" do
    params = copy(@valid_params)
    params['attack'] = true
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::UnexpectedParam)
  end

  it "should prevent XSS attack on unexpected param name being listed in the exception message" do
    params = copy(@valid_params)
    params["7e22c<script>alert('xss vulnerability')</script>e88ff3f0952"] = 1
    escaped_error_message = /7e22c&lt;script&gt;alert\(.*\)&lt;\/script&gt;e88ff3f0952/
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::UnexpectedParam, escaped_error_message)
  end

  it "should make sure that optional params marked as not false are being set" do
    params = copy(@valid_params)
    ParamsVerification.validate!(params, @service.defined_params).should be_true
    params.delete('version')
    # if omitted, the param should not raise an exception
    ParamsVerification.validate!(params, @service.defined_params).should be_true
    params['version'] = ''
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamValue)
  end

  it "should allow optional null integer params" do
    service = WeaselDiesel.new("spec")
    service.params do |p|
      p.integer :id, :optional => true, :null => true
    end
    params = {"id" => ""}
    lambda{ ParamsVerification.validate!(params, service.defined_params) }.should_not raise_exception
    params = {"id" => nil}
    lambda{ ParamsVerification.validate!(params, service.defined_params) }.should_not raise_exception
  end
end
