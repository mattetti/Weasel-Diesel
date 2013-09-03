# Web Service DSL

[![CI Build Status](https://secure.travis-ci.org/mattetti/Weasel-Diesel.png?branch=master)](http://travis-ci.org/mattetti/Weasel-Diesel)

Weasel Diesel is a DSL to describe and document your web API.

To get you going quickly, see the [generator for sinatra apps](https://github.com/mattetti/wd-sinatra).
The wd_sinatra gem allows you to generate the structure for a sinatra app using Weasel Diesel and with lots of goodies.
Updating is trivial since the core features are provided by this library and the wd_sinatra gem.

You can also check out this Sinatra-based [example
application](https://github.com/mattetti/sinatra-web-api-example) that
you can fork and use as a base for your application.

* API Docs: http://rubydoc.info/gems/weasel_diesel/frames
* Google Group: https://groups.google.com/forum/#!forum/weaseldiesel

DSL examples:

``` ruby
describe_service "/hello_world" do |service|
  service.formats   :json
  service.http_verb :get # default verb, can be ommitted.
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

    describe_service "/wsdsl/test.xml" do |service|
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

## INPUT DSL

As shown in the two examples above, input parameters can be:
* optional or required
* namespaced
* typed
* marked as not being null if passed
* set to have a value defined in a list
* set to have a min value
* set to have a min length
* set to have a max value
* set to have a max length
* documented

Most of these settings are used to verify the input requests.

### Supported defined types:

* integer
* float, decimal
* string
* boolean
* array (comma delimited string)
* binary, file

#### Note regarding required vs optional params.

You can't set a required param to be `:null => true`, if you do so, the
setting will be ignored since all required params have to be present.

If you set an optional param to be `:null => false`, the verification
will only fail if the param was present in the request but the passed
value is nil. You might want to use that setting if you have an optional
param that, by definition isn't required but, if passed has to not be
null.


### Validation and other param options

You can set many rules to define an input parameter.
Here is a quick overview of the available param options, check the specs for more examples.
Options can be combined.

* `required` by default the defined optional input parameters are
  optional. However their presence can be required by using this flag.
  (Setting `:null => true` will be ignored if the paramter is required)
  Example: `service.param.string :id, :required => true`
* `in` or `options` limits the range of the possible values being
  passed. Example: `service.param.string :skills, :options %w{ruby scala clojure}`
* `default` sets a value for your in case you don't pass one. Example:
  `service.param.datetime :timestamp, :default => Time.now.iso8601`
* `min_value` forces the param value to be equal or greater than the
  option's value. Example: `service.param.integer :age, :min_value => 21
* `max_value` forces the param value to be equal or less than the
  options's value. Example: `service.param.integer :votes, :max_value => 7
* `min_length` forces the length of the param value to be equal or
  greater than the option's value. Example: `service.param.string :name, :min_length => 2`
* `max_length` forces the length of the param value to be equal or
  lesser than the options's value. Example: `service.param.string :name, :max_length => 251`
* `null` in the case of an optional parameter, if the parameter is being
  passed, the value can't be nil or empty.
* `doc` document the param.

### Namespaced/nested object

Input parameters can be defined nested/namespaced.
This is particuliarly frequent when using Rails for instance.

```ruby
service.params do |param|
    param.string :framework,
      :in => ['RSpec', 'Bacon'],
      :required => true,
      :doc => "The test framework used, could be one of the two following: #{WeaselDieselSpecOptions.join(", ")}."

    param.datetime :timestamp, :default => Time.now
    param.string   :alpha,     :in      => ['a', 'b', 'c']
    param.string   :version,   :null    => false, :doc => "The version of the framework to use."
    param.integer  :num,       :min_value => 42,  :max_value => 1000, :doc => "The number to test"
    param.string   :name,      :min_length => 5, :max_length => 25
  end

  service.params.namespace :user do |user|
    user.integer :id, :required => :true
    user.string  :sex, :in => %Q{female, male}
    user.boolean :mailing_list, :default => true, :doc => "is the user subscribed to the ML?"
    user.array   :skills, :in => %w{ruby js cooking}
  end

  service.params.namespace :attachment, :null => true do |attachment|
    attachment.string :url, :required => true
  end
```



Here is the same type of input but this time using a JSON jargon,
`namespace` and `object` are aliases and can therefore can be used based
on how the input type.

```ruby
# INPUT using 1.9 hash syntax
service.params do |param|
  param.integer :playlist_id,
            doc: "The ID of the playlist to which the track belongs.",
            required: true
  param.object :track do |track|
    track.string :title,
                  doc: "The title of the track.",
                  required: true
    track.string :album_title,
                  doc: "The title of the album to which the track belongs.",
                  required: true
    track.string :artist_name,
                  doc: "The name of the track's artist.",
                  required: true
    track.string :rdio_id,
                  doc: "The Rdio ID of the track.",
                  required: true
  end
end
```



## OUTPUT DSL


### JSON API example

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
    describe_service "/json_list" do |service|
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

Another simple examples:

Actual output:
```
{"organization": {"name": "Example"}}
```

Output DSL:
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

Actual output:
```
 {"name": "Example"}
```

Output DSL:
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

## Documentation generation

```bash
    $ weasel_diesel generate_doc <SOURCE_PATH> <DESTINATION_PATH>
```

To generate documentation for the APIs you created in the api folder. The
source path is the location of your ruby files. The destination is optional,
'doc' is the default.

Here's a [sample](https://s3.amazonaws.com/f.cl.ly/items/3V1Q123b2E2c0z350V0n/index.html)
of what the generator documentation looks like.

## Test Suite & Dependencies

The test suite requires `rspec`, `rack`, and `sinatra` gems.

## Copyright

Copyright (c) 2012 Matt Aimonetti. See LICENSE for
further details.
