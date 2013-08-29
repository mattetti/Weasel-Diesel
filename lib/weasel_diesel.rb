require_relative 'inflection'
require_relative 'params'
require_relative 'response'
require_relative 'documentation'
require_relative 'ws_list'
require 'weasel_diesel/dsl'

# WeaselDiesel offers a web service DSL to define web services,
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
#  WeaselDiesel
#    |
#    |__ service options (name, url, SSL, auth required formats, verbs, controller name, action, version, extra)
#    |__ defined_params (instance of WeaselDiesel::Params)
#    |             |    |  |_ Optional param rules
#    |             |    |_ Required param rules
#    |             |_ Namespaced params (array containing nested optional and required rules)
#    |__ response (instance of WeaselDiesel::Response)
#    |      |_ elements (array of elements with each element having a name, type, attributes and vectors
#    |      |      |  |_ attributes (array of WeaselDiesel::Response::Attribute, each attribute has a name, a type, a doc and some extra options)
#    |      |      |_ vectors (array of WeaselDiesel::Response::Vector), each vector has a name, obj_type, & an array of attributes
#    |      |           |_ attributes (array of WeaselDiesel::Response::Attribute, each attribute has a name, a type and a doc)
#    |      |_ arrays (like elements but represent an array of objects)
#    |
#    |__ doc (instance of WeaselDiesel::Documentation)
#       |  |  | |_ overal) description
#       |  |  |_ examples (array of examples as strings)
#       |  |_ params documentation (Hash with the key being the param name and the value being the param documentation)
#       |_ response (instance of Documentation.new)
#            |_ elements (array of instances of WeaselDiesel::Documentation::ElementDoc, each element has a name and a list of attributes)
#                  |_ attributes (Hash with the key being the attribute name and the value being the attribute's documentation)
#
# @since 0.0.3
# @api public
class WeaselDiesel

  # Returns the service url
  #
  # @return [String] The service url
  # @api public
  attr_reader :url

  # List of all the service params
  #
  # @return [Array<WeaselDiesel::Params>]
  # @api public
  attr_reader :defined_params

  # Documentation instance containing all the service doc
  #
  # @return [WeaselDiesel::Documentation]
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
  # @param [String] url Service's url ( the url will automatically be prepended a slash if it doesn't already contain one.
  # @see #describe_service See how this class is usually initialized using `describe_service`
  # @api public
  def initialize(url)
    @url                 = url.start_with?('/') ? url : "/#{url}"
    @defined_params      = WeaselDiesel::Params.new
    @doc                 = WeaselDiesel::Documentation.new
    @response            = WeaselDiesel::Response.new
    # TODO: extract to its own optional lib
    if WeaselDiesel.use_controller_dispatch
      @name                = extract_service_root_name(url)
      if WeaselDiesel.use_pluralized_controllers
        base_name = ExtlibCopy::Inflection.pluralize(ExtlibCopy::Inflection.singular(name))
        @controller_name     = "#{ExtlibCopy.classify(base_name)}Controller"
      else
        @controller_name     = "#{ExtlibCopy.classify(name)}Controller"
      end
      @action              = extract_service_action(url)
    end
    #
    @verb                = :get
    @formats             = []
    @version             = '0.1'
    @ssl                 = false
    @auth_required       = true
    @extra               = {}
  end

  # Checks the WeaselDiesel flag to see if the controller names are pluralized.
  #
  # @return [Boolean] The updated value, default to false
  # @api public
  # @since 0.1.1
  def self.use_pluralized_controllers
    @pluralized_controllers ||= false
  end

  # Sets a WeaselDiesel global flag so all controller names will be automatically pluralized.
  #
  # @param [Boolean] True if the controllers are pluralized, False otherwise.
  #
  # @return [Boolean] The updated value
  # @api public
  # @since 0.1.1
  def self.use_pluralized_controllers=(val)
    @pluralized_controllers = val
  end

  # Checks the WeaselDiesel flag to see if controller are used to dispatch requests.
  # This allows apps to use this DSL but route to controller/actions.
  #
  # @return [Boolean] The updated value, default to false
  # @api public
  # @since 0.3.0
  # @deprecated
  def self.use_controller_dispatch
    @controller_dispatch
  end

  # Sets a WeaselDiesel global flag so the controller settings can be generated
  # Setting this flag will automatically set the controller/action names.
  # @param [Boolean] True if the controllers are pluralized, False otherwise.
  #
  # @return [Boolean] The updated value
  # @api public
  # @since 0.1.1
  # @deprecated
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
  # @deprecated
  def controller_dispatch(app)
    unless @controller
      klass = @controller_name.split("::")
      begin
        @controller = klass.inject(Object) { |const,k| const.const_get(k) }
      rescue NameError => e
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
  # @see WeaselDiesel::Params
  #
  # @return [WeaselDiesel::Params] The defined params
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
  # @return [Array<WeaselDiesel::Params::Rule>] Only the required param rules
  # @api public
  def required_rules
    @defined_params.list_required
  end

  # Returns an array of optional param rules
  #
  # @return [Array<WeaselDiesel::Params::Rule>]Only the optional param rules
  # @api public
  def optional_rules
    @defined_params.list_optional
  end

  # Returns an array of namespaced params
  # @see WeaselDiesel::Params#namespaced_params
  #
  # @return [Array<WeaselDiesel::Params>] the namespaced params
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
  # @return [WeaselDiesel::Response]
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
  # @yield [WeaselDiesel::Documentation]
  #
  # @return [WeaselDiesel::Documentation] The service documentation object
  # @api public
  def documentation
    if block_given?
      yield(doc)
    else
      doc
    end
  end

  # Assign a route loading point to compare two routes.
  # Using this point value, one can load routes with the more globbing
  # routes later than short routes.
  #
  # @return [Integer] point value
  def route_loading_point
    url =~ /(.*?):(.*?)[\/\.](.*)/
    return url.size if $1.nil?
    # The shortest the prepend, the further the service should be loaded
    prepend = $1.size
    # The shortest the placeholder, the further it should be in the queue
    place_holder = $2.size
     # The shortest the trail, the further it should be in the queue
    trail = $3.size
    prepend + place_holder + trail
  end

  # Compare two services using the route loading point
  def <=> (other)
    route_loading_point <=> other.route_loading_point
  end

  # Takes input param documentation and copy it over to the document object.
  # We need to do that so the params can be both documented when a param is defined
  # and in the documentation block.
  # @api private
  def sync_input_param_doc
    defined_params.namespaced_params.each do |prms|
      doc.namespace(prms.space_name.name) do |ns|
        prms.list_optional.each do |rule|
          ns.param(rule.name, rule.options[:doc]) if rule.options[:doc]
        end
        prms.list_required.each do |rule|
          ns.param(rule.name, rule.options[:doc]) if rule.options[:doc]
        end
      end
    end

    defined_params.list_optional.each do |rule|
      doc.param(rule.name, rule.options[:doc]) if rule.options[:doc]
    end

    defined_params.list_required.each do |rule|
      doc.param(rule.name, rule.options[:doc]) if rule.options[:doc]
    end
  end

  # Left for generators to implement. It's empty because WD itself isn't concerned
  # with implementation, but needs it defined so doc generation can read WD web
  # service definitions.
  def implementation(&block)
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
