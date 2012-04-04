# Web Service DSL

Weasel Diesel is a simple DSL allowing developers to simply describe and
document their web APIS. 
The DSL is already setup on top of Sinatra in this [example
application](https://github.com/mattetti/sinatra-web-api-example) that
you can simply fork and use as a base for your application.

DSL examples:

``` ruby
describe_service "hello_world" do |service|
  service.formats   :json
  service.http_verb :get
  service.disable_auth # on by default

  # INPUT
  service.param.string  :name, :default => 'World'

  # OUTPUT
  service.response do |response|
    response.object do |obj|
	    obj.string :message, :doc => "The greeting message sent back. Defaults to 'World'"
      obj.datetime :at, :doc => "The timestamp of when the message was dispatched"
	  end
  end

  # DOCUMENTATION
  service.documentation do |doc|
  	doc.overall "This service provides a simple hello world implementation example."
  	doc.param :name, "The name of the person to greet."
  	doc.example "<code>curl -I 'http://localhost:9292/hello_world?name=Matt'</code>"
 end

  # ACTION/IMPLEMENTATION (specific to the sinatra app example, can
  # instead be set to call a controller action)
  service.implementation do
    {:message => "Hello #{params[:name]}", :at => Time.now}.to_json
  end

end
```

``` ruby
    describe_service "hello_world" do |service|
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
        doc.example "<code>http://example.com/hello_world.xml?name=Matt</code>"
     end

    end
```

Or a more complex example:

``` ruby
    SpecOptions = ['RSpec', 'Bacon'] # usually pulled from a model

    describe_service "wsdsl/test.xml" do |service|
      service.formats  :xml, :json
      service.http_verb :get
      
      service.params do |p|
        p.string :framework, :in => SpecOptions, :null => false, :required => true
       
        p.datetime :timestamp, :default => Time.now
        p.string   :alpha,     :in      => ['a', 'b', 'c']
        p.string   :version,   :null    => false
        p.integer  :num,      :minvalue => 42
      end
      
      # service.param :delta, :optional => true, :type => 'float'
      # All params are optional by default.
      # service.param :epsilon, :type => 'string'
      
      service.params.namespace :user do |user|
        user.integer :id, :required => :true
      end
      
      # the response contains a list of player creation ratings each object in the list 
      
      service.response do |response|
        response.element(:name => "player_creation_ratings") do |e|
          e.attribute  :id          => :integer, :doc => "id doc"
          e.attribute  :is_accepted => :boolean, :doc => "is accepted doc"
          e.attribute  :name        => :string,  :doc => "name doc"
          
          e.array :name => 'player_creation_rating', :type => 'PlayerCreationRating' do |a|
            a.attribute :comments  => :string,  :doc => "comments doc"
            a.attribute :player_id => :integer, :doc => "player_id doc"
            a.attribute :rating    => :integer, :doc => "rating doc"
            a.attribute :username  => :string,  :doc => "username doc"
          end
        end
      end
      
      service.documentation do |doc|
        # doc.overall <markdown description text>
        doc.overall <<-DOC
         This is a test service used to test the framework.
        DOC
        
        # doc.params <name>, <definition>
        doc.params :framework, "The test framework used, could be one of the two following: #{SpecOptions.join(", ")}."
        doc.params :version, "The version of the framework to use."
        
        # doc.example <markdown text>
        doc.example <<-DOC
    The most common way to use this service looks like that:
        http://example.com/wsdsl/test.xml?framework=rspec&version=2.0.0
        DOC
      end
    end
```

## JSON APIs

This library was designed with XML responses in mind and JSON support
was added later on which explains why some response methods are aliases.
Consider the following JSON response:

``` 
    { people: [ 
      { 
        id : 1, 
        online : false,
        created_at : 123123123123, 
        team : {
          id : 1231,
          score : 123.32
        }
      }, 
      { 
        id : 2, 
        online : true,
        created_at : 123123123123, 
        team: {
          id : 1233,
          score : 1.32
        }
      }, 
    ] }
```

It would be described as follows:

``` ruby
    describe_service "json_list" do |service|
      service.formats  :json
      service.response do |response|
        response.array :people do |node|
          node.integer :id
          node.boolean :online
          node.datetime :created_at
          node.object :team do |team|
            team.integer :id
            team.float :score, :null => true
          end
        end
      end
    end
```

Nodes/elements can also use some meta attributes. Currently the
following meta attributes are available:

* key (refers to an attribute name that is key to this object)
* type (refers to the type of object described, valuable when using JSON
  cross OO based apps.

JSON response validation can be done using an optional module.
Look at the spec/json_response_verification_spec.rb file for a complete
example. The goal of this module is to help automate API testing by
validating the data structure of the returned object.

## Test suite

This library comes with a test suite requiring Ruby 1.9.2
The following gems need to be available:
Rspec, Rack, Sinatra

## RUBY 1.8 warning

This library was written for Ruby 1.9 and 1.8 support was added later on
via the backports libary and some tweaks. However, because unlike in
ruby 1.9, the hash insert order isn't kept in 1.8 the following syntax
isn't supported and the alternative version needs to be used:

``` ruby
    service.response do |response|
      response.element(:name => "player_creation_ratings") do |e|
        e.attribute  :id          => :integer, :doc => "id doc"
        e.attribute  :is_accepted => :boolean, :doc => "is accepted doc"
        e.attribute  :name        => :string,  :doc => "name doc"
      end
    end
```

Instead the following version should be used:

``` ruby
    service.response do |response|
      response.element(:name => "player_creation_ratings") do |e|
        e.integer  :id, :doc => "id doc"
        e.boolean  :is_accepted, :doc => "is accepted doc"
        e.string   :name, :doc => "name doc"
      end
    end
```

Both code snippets do the exact same thing but the first version is 1.9
only.



## Copyright

Copyright (c) 2012 Matt Aimonetti. See LICENSE for
further details.
