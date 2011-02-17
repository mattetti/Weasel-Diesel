require File.expand_path('params', File.dirname(__FILE__))
require File.expand_path('documentation', File.dirname(__FILE__))
require File.expand_path('response', File.dirname(__FILE__))

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
#    |__ service options (name, url, SSL, auth rquired formats, verbs, controller name, action, version)
#    |__ defined_params (instance of WSDSL::Params)
#    |             |    |  |_ Optional param rules
#    |             |    |_ Required param rules
#    |             |_ Namespaced params (array containing nested optional and required rules)
#    |__ response (instance of WSDSL::Response)
#    |      |_ elements (array of elements with each element having a name, type, attributes and vectors
#    |            |  |_ attributes (array of WSDSL::Response::Attribute, each attribute has a name, a type, a doc and some extra options)
#    |            |_ vectors (array of WSDSL::Response::Vector), each vector has a name, obj_type, & an array of attributes
#    |                 |_ attributes (array of WSDSL::Response::Attribute, each attribute has a name, a type and a doc)
#    |__ doc (instance of WSDSL::Documentation)
#       |  |  | |_ overal) description
#       |  |  |_ examples (array of examples as strings)
#       |  |_ params documentation (Hash with the key being the param name and the value being the param documentation)
# 
# 
# 
#       |_ response (instance of Documentation.new)
#            |_ elements (array of instances of WSDSL::Documentation::ElementDoc, each element has a name and a list of attributes)
#                  |_ attributes (Hash with the key being the attribute name and the value being the attribute's documentation)
# 
# @since 0.1
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
  attr_reader :action
  
  # Name of the controller associated with the service
  #
  # @return [String]
  # @api public
  attr_reader :controller_name
  
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
    @name                = extract_service_root_name(url)
    @controller_name     = "#{name.classify}Controller"
    @action              = extract_service_action(url)
    @verb                = :get
    @formats             = []
    @version             = '0.1'
    @ssl                 = false
    @auth_required       = true
  end
  
  # Offers a way to dispatch the service at runtime
  # Basically, it dispatches the request to the defined controller/action
  # The full request cycle looks like that:
  # client -> webserver -> rack -> env -> [service dispatcher] -> controller action -> rack -> webserver -> client
  # @param [Object] app Reference object such as a Sinatra::Application to be passed to the controller.
  #
  # @return [#to_s] The response from the controller action
  # @api private
  def dispatch(app)
    unless @controller
      if WSController.const_defined?(@controller_name)
        @controller = WSController.const_get(@controller_name)
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


end
