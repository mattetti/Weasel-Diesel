# Wrapper module to keep track of all defined services
#
# @api public
module WSList

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
  
end

