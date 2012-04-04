# Module used to extend {WeaselDiesel} and add {#load_sinatra_route} to services.
# This code is Sinatra specific and therefore lives outside the {WeaselDiesel}
# @see {WeaselDiesel}
# @api public
module WeaselDieselSinatraExtension
  
  # Defines a sinatra service route based on its settings
  #
  # @return [Nil]
  # @api private
  def load_sinatra_route
    service     = self
    upcase_verb = service.verb.to_s.upcase
    puts "/#{self.url} -> #{self.controller_name}##{self.action} - (#{upcase_verb})"

    # Define the route directly to save some object allocations on the critical path
    # Note that we are using a private API to define the route and that unlike sinatra usual DSL
    # we do NOT define a HEAD route for every GET route.
    Sinatra::Base.send(:route, upcase_verb, "/#{self.url}") do
      service.controller_dispatch(self)
    end

    # Other alternative to the route definition, this time using the public API
    # self.send(verb, "/#{service.url}") do
    #   service.controller_dispatch(self)
    # end

  end
  
end
