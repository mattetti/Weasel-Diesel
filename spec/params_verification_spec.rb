require_relative "spec_helper"

describe ParamsVerification do
  
  def app
    Sinatra::Application
  end
  
  before :all do
    @service = WSList.all.find{|s| s.url == 'services/test.xml'}
    @service.should_not be_nil
    @valid_params = {'framework' => 'RSpec', 'version' => '1.02', 'user' => {'id' => '123'}}
  end
  
  it "should validate valid params" do
    lambda{ ParamsVerification.validate!(@valid_params, @service.defined_params) }.should_not raise_exception
  end
  
  it "should return the params" do
    returned_params = ParamsVerification.validate!(@valid_params, @service.defined_params)
    returned_params.should be_an_instance_of(Hash)
    returned_params.keys.size.should >= 3
  end
  
  it "should set the default values" do
    @valid_params['timestamp'].should be_nil
    returned_params = ParamsVerification.validate!(@valid_params, @service.defined_params)
    returned_params['timestamp'].should_not be_nil
  end
  
  it "should raise an exception when a required param is missing" do
    params = @valid_params.dup
    params.delete('framework')
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::MissingParam)
  end
  
  it "should raise an exception when a param is of the wrong type" do
    params = @valid_params.dup
    params['user']['id'] = 'abc'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamType)
  end
  
  it "should raise an exception when a param is under the minvalue" do
    params = @valid_params.dup
    params['num'] = 1
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamType)
  end
  
  it "should raise an exception when a param isn't in the param option list" do
    params = @valid_params.dup
    params['alpha'] = 'z'
    lambda{ ParamsVerification.validate!(params, @service.defined_params) }.should raise_exception(ParamsVerification::InvalidParamType)
  end
  
  it "should validate that no params are passed when accept_no_params! is set on a service" do
    service = WSList.all.find{|s| s.url == "services/test_no_params.xml"}
    service.should_not be_nil
    lambda{ ParamsVerification.validate!(@valid_params, service.defined_params) }.should raise_exception
  end
  
end
