require File.expand_path('inflection', File.dirname(__FILE__))
require File.expand_path('params', File.dirname(__FILE__))
require File.expand_path('response', File.dirname(__FILE__))
require File.expand_path('documentation', File.dirname(__FILE__))
require File.expand_path('ws_list', File.dirname(__FILE__))

# WSDSL offers a web service DSL to define web services,
# their params, http verbs, formats expected as well as the documentation
# for all these aspects of a web service.
#
# This DSL is only meant to describe a web service and isn't meant to cover any type 
# of implementation details. It is meant to be framework/tool agnostic.
#
# However, tools can be built around the Web Service DSL data structure to extract documentation,
# generate routing information, verify that an incoming request is valid, generate automated tests...
#
# 
# 
#  WSDSL
#    |
#    |__ service options (name, url, SSL, auth required formats, verbs, controller name, action, version, extra)
#    |__ defined_params (instance of WSDSL::Params)
#    |             |    |  |_ Optional param rules
#    |             |    |_ Required param rules
#    |             |_ Namespaced params (array containing nested optional and required rules)
#    |__ response (instance of WSDSL::Response)
#    |      |_ elements (array of elements with each element having a name, type, attributes and vectors
#    |      |      |  |_ attributes (array of WSDSL::Response::Attribute, each attribute has a name, a type, a doc and some extra options)
#    |      |      |_ vectors (array of WSDSL::Response::Vector), each vector has a name, obj_type, & an array of attributes
#    |      |           |_ attributes (array of WSDSL::Response::Attribute, each attribute has a name, a type and a doc)
#    |      |_ arrays (like elements but represent an array of objects)
#    |
#    |__ doc (instance of WSDSL::Documentation)
#       |  |  | |_ overal) description
#       |  |  |_ examples (array of examples as strings)
#       |  |_ params documentation (Hash with the key being the param name and the value being the param documentation)
#       |_ response (instance of Documentation.new)
#            |_ elements (array of instances of WSDSL::Documentation::ElementDoc, each element has a name and a list of attributes)
#                  |_ attributes (Hash with the key being the attribute name and the value being the attribute's documentation)
# 
# @since 0.0.3
# @api public
class WSDSL
  
  # Returns the service url
  #
  # @return [String] The service url
  # @api public
  attr_reader :url
  
  # List of all the service params
  #
  # @return [Array<WSDSL::Params>]
  # @api public
  attr_reader :defined_params
  
  # Documentation instance containing all the service doc
  #
  # @return [WSDSL::Documentation]
  # @api public
  attr_reader :doc
  
  # The HTTP verb supported
  #
  # @return [Symbol]
  # @api public
  attr_reader :verb
  
  # Service's version
  #
  # @return [String]
  # @api public
  attr_reader :version
  
  # Controller instance associated with the service
  #
  # @return [WSController]
  # @api public
  attr_reader :controller
  
  # Name of the controller action associated with the service 
  #
  # @return [String]
  # @api public
  attr_accessor :action
  
  # Name of the controller associated with the service
  #
  # @return [String]
  # @api public
  attr_accessor :controller_name
  
  # Name of the service
  #
  # @return [String]
  # @api public
  attr_reader :name
  
  # Is SSL required?
  #
  # @return [Boolean]
  # @api public
  attr_reader :ssl
  
  # Is authentication required?
  #
  # @return [Boolean]
  # @api public
  attr_reader :auth_required

  # Extra placeholder to store data in based on developer's discretion.
  # 
  # @return [Hash] A hash storing extra data based.
  # @api public
  # @since 0.1
  attr_reader :extra
  
  # Service constructor which is usually used via {Kernel#describe_service}
  #
  # @param [String] url Service's url
  # @see #describe_service See how this class is usually initialized using `describe_service`
  # @api public
  def initialize(url)
    @url                 = url
    @defined_params      = WSDSL::Params.new
    @doc                 = WSDSL::Documentation.new
    @response            = WSDSL::Response.new
    if WSDSL.use_controller_dispatch
      @name                = extract_service_root_name(url)
      if WSDSL.use_pluralized_controllers
        base_name = ExtlibCopy::Inflection.pluralize(ExtlibCopy::Inflection.singular(name))
        @controller_name     = "#{ExtlibCopy.classify(base_name)}Controller"
      else
        @controller_name     = "#{ExtlibCopy.classify(name)}Controller"
      end
      @action              = extract_service_action(url)
    end
    @verb                = :get
    @formats             = []
    @version             = '0.1'
    @ssl                 = false
    @auth_required       = true
    @extra               = {}
  end
  
  # Checks the WSDSL flag to see if the controller names are pluralized.
  #
  # @return [Boolean] The updated value, default to false
  # @api public
  # @since 0.1.1
  def self.use_pluralized_controllers
    @pluralized_controllers ||= false
  end

  # Sets a WSDSL global flag so all controller names will be automatically pluralized.
  #
  # @param [Boolean] True if the controllers are pluralized, False otherwise.
  # 
  # @return [Boolean] The updated value
  # @api public
  # @since 0.1.1
  def self.use_pluralized_controllers=(val)
    @pluralized_controllers = val
  end

  # Checks the WSDSL flag to see if controller are used to dispatch requests.
  # This allows apps to use this DSL but route to controller/actions.
  #
  # @return [Boolean] The updated value, default to false
  # @api public
  # @since 0.3.0
  def self.use_controller_dispatch
    @controller_dispatch
  end

  # Sets a WSDSL global flag so the controller settings can be generated
  # Setting this flag will automatically set the controller/action names.
  # @param [Boolean] True if the controllers are pluralized, False otherwise.
  # 
  # @return [Boolean] The updated value
  # @api public
  # @since 0.1.1
  def self.use_controller_dispatch=(val)
    @controller_dispatch = val
  end

  # Offers a way to dispatch the service at runtime
  # Basically, it dispatches the request to the defined controller/action
  # The full request cycle looks like that:
  # client -> webserver -> rack -> env -> [service dispatcher] -> controller action -> rack -> webserver -> client
  # @param [Object] app Reference object such as a Sinatra::Application to be passed to the controller.
  #
  # @return [#to_s] The response from the controller action
  # @api private
  def controller_dispatch(app)
    unless @controller
      if Object.const_defined?(@controller_name)
        @controller = Object.const_get(@controller_name)
      else
        raise "The #{@controller_name} class was not found"
      end
    end
    # We are passing the service object to the controller so the
    # param verification could be done when the controller gets initialized.
    @controller.new(app, self).send(@action)
  end
  
  # Returns the defined params 
  # for DSL use only!
  # To keep the distinction between the request params and the service params
  # using the +defined_params+ accessor is recommended.
  # @see WSDSL::Params
  #
  # @return [WSDSL::Params] The defined params
  # @api public
  def params
    if block_given?
      yield(@defined_params)
    else
      @defined_params
    end
  end
  alias :param :params
 
  # Returns true if the DSL defined any params
  #
  # @return [Boolean]
  def params?
    !(required_rules.empty? && optional_rules.empty? && nested_params.empty?)
  end

  # Returns an array of required param rules
  #
  # @return [Array<WSDSL::Params::Rule>] Only the required param rules
  # @api public
  def required_rules
    @defined_params.list_required
  end
  
  # Returns an array of optional param rules
  #
  # @return [Array<WSDSL::Params::Rule>]Only the optional param rules
  # @api public
  def optional_rules
    @defined_params.list_optional
  end
  
  # Returns an array of namespaced params
  # @see WSDSL::Params#namespaced_params
  #
  # @return [Array<WSDSL::Params>] the namespaced params
  # @api public
  def nested_params
    @defined_params.namespaced_params
  end
  
  # Mark that the service doesn't require authentication.
  # Note: Authentication is turned on by default
  #
  # @return [Boolean]
  # @api public
  def disable_auth
    @auth_required = false
  end
  
  # Mark that the service requires a SSL connection
  #
  # @return [Boolean]
  # @api public
  def enable_ssl
    @ssl = true
  end
  
  # Mark the current service as not accepting any params.
  # This is purely for expressing the developer's objective since 
  # by default an error is raise if no params are defined and some
  # params are sent.
  # 
  # @return [Nil]
  # @api public
  def accept_no_params!
    # no op operation since this is the default behavior
    # unless params get defined. Makes sense for documentation tho.
  end
  
  # Returns the service response
  # @yield The service response object
  #
  # @return [WSDSL::Response]
  # @api public
  def response
    if block_given?
      yield(@response)
    else
      @response
    end
  end
  
  # Sets or returns the supported formats
  # @param [String, Symbol] f_types Format type supported, such as :xml
  #
  # @return [Array<Symbol>]   List of supported formats
  # @api public
  def formats(*f_types)
    f_types.each{|f| @formats << f unless @formats.include?(f) }
    @formats
  end
  
  # Sets the accepted HTTP verbs or return it if nothing is passed.
  #
  # @return [String, Symbol]
  # @api public
  def http_verb(s_verb=nil)
    return @verb if s_verb.nil?
    @verb = s_verb.to_sym
    # Depending on the service settings and url, the service action might need to be updated.
    # This is how we can support restful routes where a PUT request automatically uses the update method.
    update_restful_action(@verb)
    @verb
  end
  
  # Yields and returns the documentation object
  # @yield [WSDSL::Documentation]
  #
  # @return [WSDSL::Documentation] The service documentation object
  # @api public
  def documentation
    yield(doc)
  end

  SERVICE_ROOT_REGEXP = /(.*?)[\/\(\.]/  
  SERVICE_ACTION_REGEXP = /[\/\(\.]([a-z0-9_]+)[\/\(\.\?]/i
  SERVICE_RESTFUL_SHOW_REGEXP = /\/:[a-z0-9_]+\.\w{3}$/
  
  private
  
  # extracts the service root name out of the url using a regexp
  def extract_service_root_name(url)
    url[SERVICE_ROOT_REGEXP, 1] || url
  end
  
  # extracts the action name out of the url using a regexp
  # Defaults to the list action
  def extract_service_action(url)
    if url =~ SERVICE_RESTFUL_SHOW_REGEXP
      'show'
    else
      url[SERVICE_ACTION_REGEXP, 1] || 'list'
    end
  end
  
  # Check if we need to use a restful route in which case we need
  # to update the service action
  def update_restful_action(verb)
    if verb != :get && @action && @action == 'list'
      case verb
      when :post
        @action = 'create'
      when :put
        @action = 'update'
      when :delete
        @action = 'destroy'
      end
    end
  end

end

# Extending the top level module to add some helpers
#
# @api public
module Kernel

  # Base DSL method called to describe a service
  #
  # @param [String] url The url of the service to add.
  # @yield [WSDSL] The newly created service.
  # @return [Array] The services already defined
  # @example Describing a basic service
  #   describe_service "hello-world.xml" do |service|
  #     # describe the service
  #   end
  #
  # @api public
  def describe_service(url, &block)
    service = WSDSL.new(url)
    yield service
    WSList.add(service)
    service
  end
  
end
