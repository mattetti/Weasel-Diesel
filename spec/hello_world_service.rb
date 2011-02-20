describe_service "hello_world.xml" do |service|
  service.formats    :xml
  service.http_verb :get
  service.disable_auth # on by default

  service.param.string  :name, :default => 'World'

  service.response do |response|
    response.element(:name => "greeting") do |e|
	    e.attribute "message" => :string, :doc => "The greeting message sent back."
	  end
  end

  service.documentation do |doc|
  	doc.overall "This service provides a simple hello world implementation example."
  	doc.params :name, "The name of the person to greet."
  	doc.example "<code>http://ps3.yourgame.com/hello_world.xml?name=Matt</code>"
 end

end
