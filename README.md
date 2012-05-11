# Web Service DSL

Weasel Diesel is a DSL to describe and document your web API. 

To get you going quickly, see the [generator for sinatra apps](https://github.com/mattetti/wd-sinatra).
The wd_sinatra gem allows you to generate the structure for a sinatra app using Weasel Diesel and with lots of goodies.
Updating is trivial since the core features are provided by this library and the wd_sinatra gem.


You can also check out this Sinatra-based [example
application](https://github.com/mattetti/sinatra-web-api-example) that
you can fork and use as a base for your application.

DSL examples:

``` ruby
describe_service "hello_world" do |service|
  service.formats   :json
  service.http_verb :get
  service.disable_auth # on by default

  # INPUT
  service.param.string  :name, :default => 'World', :doc => "The name of the person to greet."

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
  	doc.example "<code>curl -I 'http://localhost:9292/hello_world?name=Matt'</code>"
 end

  # ACTION/IMPLEMENTATION (specific to the sinatra app example, can
  # instead be set to call a controller action)
  service.implementation do
    {:message => "Hello #{params[:name]}", :at => Time.now}.to_json
  end

end
```

Or a more complex example using XML:

``` ruby
    SpecOptions = ['RSpec', 'Bacon'] # usually pulled from a model

    describe_service "wsdsl/test.xml" do |service|
      service.formats  :xml, :json
      service.http_verb :get
      
      # INPUT
      service.params do |p|
        p.string :framework, :in => SpecOptions, :null => false, :required => true
       
        p.datetime :timestamp, 
                   :default => Time.now, 
                   :doc => "The test framework used, could be one of the two following: #{SpecOptions.join(", ")}."

        p.string   :alpha,     :in      => ['a', 'b', 'c']
        p.string   :version,   
                   :null    => false,
                   :doc => "The version of the framework to use."
                   
        p.integer  :num,      :minvalue => 42
        p.namespace :user do |user|
          user.integer :id, :required => :true
        end
      end
      
      # OUTPUT
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
      
      # DOCUMENTATION
      service.documentation do |doc|
        # doc.overall <markdown description text>
        doc.overall <<-DOC
         This is a test service used to test the framework.
        DOC
        
        # doc.example <markdown text>
        doc.example <<-DOC
    The most common way to use this service looks like that:
        http://example.com/wsdsl/test.xml?framework=rspec&version=2.0.0
        DOC
      end
    end
```

## JSON APIs

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

Nodes/elements can also use some meta-attributes including:

* `key` : refers to an attribute name that is key to this object
* `type` : refers to the type of object described, valuable when using JSON across OO based apps.

JSON response validation can be done using an optional module as shown in 
(spec/json_response_verification_spec.rb)[https://github.com/mattetti/Weasel-Diesel/blob/master/spec/json_response_verification_spec.rb].
The goal of this module is to help automate API testing by
validating the data structure of the returned object.


Other JSON DSL examples:

```
{"organization": {"name": "Example"}}
```

``` Ruby
  describe_service "example" do |service|
    service.formats  :json
    service.response do |response|
      response.object :organization do |node|
        node.string :name
      end
    end
  end
```

``` 
 {"name": "Example"}
```

``` Ruby
describe_service "example" do |service|
  service.formats  :json
  service.response do |response|
    response.object do |node|
      node.string :name
    end
  end
end
```




## Test Suite & Dependencies

The test suite requires Ruby 1.9.* along with `RSpec`, `Rack`, and `Sinatra` gems.

## Usage with Ruby 1.8

This library prioritizes Ruby 1.9, but 1.8 support was added 
via the backports library and some tweaks. 

However, because Ruby 1.8 hashes do not preserve insert order, the following syntax
**will not work**:

``` ruby
    service.response do |response|
      response.element(:name => "player_creation_ratings") do |e|
        e.attribute  :id          => :integer, :doc => "id doc"
        e.attribute  :is_accepted => :boolean, :doc => "is accepted doc"
        e.attribute  :name        => :string,  :doc => "name doc"
      end
    end
```

Instead, this alternate syntax must be used:

``` ruby
    service.response do |response|
      response.element(:name => "player_creation_ratings") do |e|
        e.integer  :id, :doc => "id doc"
        e.boolean  :is_accepted, :doc => "is accepted doc"
        e.string   :name, :doc => "name doc"
      end
    end
```

The end results are identical.

## Copyright

Copyright (c) 2012 Matt Aimonetti. See LICENSE for
further details.
