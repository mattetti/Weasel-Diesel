WeaselDieselSpecOptions = ['RSpec', 'Bacon'] # usually pulled from a model

describe_service "services/test.xml" do |service|
  service.formats  :xml, :json
  service.http_verb :get

  service.params do |p|
    p.string :framework, :in => WeaselDieselSpecOptions, :null => false, :required => true

    p.datetime :timestamp, :default => Time.now
    p.string   :alpha,     :in      => ['a', 'b', 'c']
    p.string   :version,   :null    => false
    p.integer  :num,      :minvalue => 42

  end

  # service.param :delta, :optional => true, :type => 'float'
  # # if the optional flag isn't passed, the param is considered required.
  # service.param :epsilon, :type => 'string'

  service.params.namespace :user do |user|
    user.integer :id, :required => :true
    user.string :sex, :in => %Q{female, male}
    user.boolean :mailing_list, :default => true
  end

  # the response contains a list of player creation ratings each object in the list

=begin
  #Format not supported by Ruby 1.8 due to hash insertion order not being maintained.
  service.response do |response|
    response.element(:name => "player_creation_ratings") do |e|
      e.attribute  :id          => :integer, :doc => "id doc"
      e.attribute  :is_accepted => :boolean, :doc => "is accepted doc"
      e.attribute  :name        => :string,  :doc => "name doc"

      e.array :player_creation_rating, 'PlayerCreationRating' do |a|
        a.attribute :comments  => :string,  :doc => "comments doc"
        a.attribute :player_id => :integer, :doc => "player_id doc"
        a.attribute :rating    => :integer, :doc => "rating doc"
        a.attribute :username  => :string,  :doc => "username doc"
      end
    end
  end
=end

  service.response do |response|
    response.element(:name => "player_creation_ratings") do |e|
      e.integer  :id, :doc => "id doc"
      e.boolean  :is_accepted, :doc => "is accepted doc"
      e.string   :name, :doc => "name doc"

      e.array :player_creation_rating, 'PlayerCreationRating' do |a|
        a.string :comments,  :doc => "comments doc"
        a.integer :player_id, :doc => "player_id doc"
        a.integer :rating, :doc => "rating doc"
        a.string :username,  :doc => "username doc"
      end
    end
  end


  service.documentation do |doc|
    # doc.overall <markdown description text>
    doc.overall <<-DOC
     This is a test service used to test the framework.
    DOC

    # doc.params <name>, <definition>
    doc.param :framework, "The test framework used, could be one of the two following: #{WeaselDieselSpecOptions.join(", ")}."
    doc.param :version, "The version of the framework to use."

    # doc.example <markdown text>
    doc.example <<-DOC
The most common way to use this service looks like that:
    http://example.com/services/test.xml?framework=rspec&version=2.0.0
    DOC
  end
end


describe_service "services/test_no_params.xml" do |service|
  service.formats  :xml
  service.http_verb :get
  service.accept_no_params!
end

describe_service "services.xml" do |service|
  service.formats  :xml
  service.http_verb :put

end

describe_service "services/array_param.xml" do |s|
  s.formats :xml
  s.http_verb :post

  s.params do |p|
    p.array :seq, :required => true
  end

end
