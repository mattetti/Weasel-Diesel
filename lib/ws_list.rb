# Wrapper module to keep track of all defined services
#
# @api public
module WSList

  class UnknownService < StandardError; end
  class DuplicateServiceDescription < StandardError; end

  module_function
  
  # Add a service to the array tracking
  # the playco services
  #
  # @param [WeaselDiesel] The service to add.
  # @return [Array<WeaselDiesel>] All the added services.
  # @raise DuplicateServiceDescription If a service is being duplicated.
  # @api public
  def add(service)
    @list ||= []
    if WSList.find(service.verb, service.url)
      raise DuplicateServiceDescription, "A service accessible via #{service.verb} #{service.url} already exists"
    end
    @list << service
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
  # @deprecated
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
  # @deprecated use #find instead since this method doesn't support a verb being passed
  #  and the url might or might not match depending on the leading slash.
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
    slashed_url = url.start_with?('/') ? url : "/#{url}"
    @list.find{|service| service.verb == verb && service.url == slashed_url}
  end
  
  
end

