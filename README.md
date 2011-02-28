# Web Service DSL

WSDSL is a simple DSL allowind developers to simply describe and
document their web APIS. For instance:


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


Or a more complex example:

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
      # if the optional flag isn't passed, the param is considered required. 
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


## Test suite

This library comes with a test suite requiring Ruby 1.9.2
The following gems need to be available:
Rspec, Rack, Sinatra


## Copyright

Copyright (c) 2011 Matt Aimonetti. See LICENSE for
further details.
