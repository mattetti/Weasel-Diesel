require 'forwardable'
require_relative '../params_verification'

# Base code shared by all service controllers
# This allows us to share code between controllers
# more precisely to render templates and in general to use sinatra helpers
#
# @see Sinatra::Base and Sinatra::Helpers
# @api public
# @author Matt Aimonetti
class SinatraServiceController
  extend Forwardable

  # The service controller might be loaded outside of a Sinatra App
  # in this case, we don't need to load the helpers
  if Object.const_defined?(:Sinatra)
    include Sinatra::Helpers
  end

  class AuthenticationFailed < StandardError; end

  # @return [WeaselDiesel] The service served by this controller
  # @api public
  attr_reader :service

  # @return [Sinatra::Application]
  # @api public
  attr_reader :app

  # @return [Hash]
  # @api public
  attr_reader :env

  # @return [Sinatra::Request]
  # @see http://rubydoc.info/github/sinatra/sinatra/Sinatra/Request
  # @api public
  attr_reader :request

  # @return [Sinatra::Response]
  # @see http://rubydoc.info/github/sinatra/sinatra/Sinatra/Response
  # @api public
  attr_reader :response

  # @return [Hash]
  # @api public
  attr_accessor :params

  # @param [Sinatra::Application] app The Sinatra app used as a reference and to access request params
  # @param [WeaselDiesel] service The service served by this controller
  # @raise [ParamError, NoParamsDefined, MissingParam, UnexpectedParam, InvalidParamType, InvalidParamValue]
  #   If the params don't validate one of the {ParamsVerification} errors will be raised.
  # @api public
  def initialize(app, service)
    @app      = app
    @env      = app.env
    @request  = app.request
    @response = app.response
    @service  = service

    # raises an exception if the params are not valid
    # otherwise update the app params with potentially new params (using default values)
    # note that if a type if mentioned for a params, the object will be cast to this object type
    @params = app.params = ParamsVerification.validate!(app.params, service.defined_params)

    # Authentication check
    if service.auth_required
      raise AuthenticationFailed unless logged_in?
    end
  end


  # Forwarding some methods to the underlying app object
  def_delegators :app, :settings, :halt, :compile_template, :session

end
