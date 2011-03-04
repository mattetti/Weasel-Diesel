# Wrapper module to keep track of all defined services
#
# @api public
module WSList

  class UnknownService < StandardError; end

  module_function
  
  # Add a service to the array tracking
  # the playco services
  #
  # @param [WSDSL] The service to add.
  # @return [Array<WSDSL>] All the added services.
  # @api public
  def add(service)
    @list ||= []
    @list << service unless @list.find{|s| s.url == service.url && s.verb == service.verb}
    @list
  end
  
  # Returns an array of services
  #
  # @return [Array<WSDSL>] All the added services.
  # @api public
  def all
    @list || []
  end

  # Returns a service based on its name
  #
  # @param [String] name The name of the service you are looking for.
  # @raise [UnknownService] if a service with the passed name isn't found.
  # @return [WSDSL] The found service.
  #
  # @api public
  def self.named(name)
    service = all.find{|service| service.name == name}
    if service.nil?
      raise UnknownService, "Service named #{name} isn't available"
    else
      service
    end
  end
  
  
end

