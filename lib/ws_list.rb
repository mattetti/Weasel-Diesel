# Wrapper module to keep track of all defined services
#
# @api public
module WSList

  class UnknownService < StandardError; end

  module_function
  
  # Add a service to the array tracking
  # the playco services
  #
  # @param [WeaselDiesel] The service to add.
  # @return [Array<WeaselDiesel>] All the added services.
  # @api public
  def add(service)
    @list ||= []
    @list << service unless @list.find{|s| s.url == service.url && s.verb == service.verb}
    @list
  end
  
  # Returns an array of services
  #
  # @return [Array<WeaselDiesel>] All the added services.
  # @api public
  def all
    @list || []
  end

  # Returns a service based on its name
  #
  # @param [String] name The name of the service you are looking for.
  # @raise [UnknownService] if a service with the passed name isn't found.
  # @return [WeaselDiesel] The found service.
  #
  # @api public
  def named(name)
    service = all.find{|service| service.name == name}
    if service.nil?
      raise UnknownService, "Service named #{name} isn't available"
    else
      service
    end
  end

  # Returns a service based on its url
  #
  # @param [String] url The url of the service you are looking for.
  # @return [Nil, WeaselDiesel] The found service.
  #
  # @api public
   def [](url)
    @list.find{|service| service.url == url}
  end
  
  # Returns a service based on its verb and url
  #
  # @param [String] verb The request method (GET, POST, PUT, DELETE)
  # @param [String] url The url of the service you are looking for.
  # @return [Nil, WeaselDiesel] The found service.
  #
  # @api public
  def find(verb, url)
    verb = verb.to_s.downcase.to_sym
    @list.find{|service| service.verb == verb && service.url == url}
  end
  
  
end

