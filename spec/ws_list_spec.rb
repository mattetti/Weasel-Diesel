require File.expand_path("spec_helper", File.dirname(__FILE__))

describe WSList do

  it "find service by verb/route" do
    service = WSList.find(:get, 'services/test.xml')
    service.should_not be_nil
    
    service.url.should == 'services/test.xml'
    service.verb.should == :get

    service = WSList.find(:delete, 'services/test.xml')
    service.url.should == 'services/test.xml'
    service.verb.should == :delete
  end
end
