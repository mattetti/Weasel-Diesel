require File.expand_path("spec_helper", File.dirname(__FILE__))

describe WSList do

  it "find service by verb/route" do
    service = WSList.find(:get, 'services/test.xml')
    service.should_not be_nil
    service.url.should == '/services/test.xml'
    service.verb.should == :get

    service = WSList.find(:delete, 'services/test.xml')
    service.url.should == '/services/test.xml'
    service.verb.should == :delete
  end

  it "finds service without or without the leading slash" do
    service = WSList.find(:get, '/services/test.xml')
    service.should_not be_nil
    service.url.should == '/services/test.xml'

    service = WSList.find(:delete, '/services/test.xml')
    service.url.should == '/services/test.xml'

    service = WSList.find(:get, 'slash/foo')
    service.should_not be_nil
    service.url.should == "/slash/foo"
  end

  it "finds the root service" do
    service = WSList.find(:get, '/')
    service.should_not be_nil
    service.extra["name"].should == "root"
  end


  it "raises an exception if a duplicate service is added" do
    lambda{ WSList.add(WeaselDiesel.new("/")) }.should raise_exception(WSList::DuplicateServiceDescription)
  end

end
