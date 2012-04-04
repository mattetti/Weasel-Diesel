class WeaselDiesel
  # Service documentation class
  #
  # @api public
  class Documentation

    # @api public
    attr_reader :desc

    # @api public
    attr_reader :params_doc

    # @api public
    attr_reader :namespaced_params

    # @api public
    attr_reader :examples

    # @api public
    attr_reader :elements

    # This class contains the documentation information regarding an element.
    # Currently, elements are only used in the response info.
    #
    # @api public
    class ElementDoc

      # @api public
      attr_reader :name, :attributes

      # @param [String] The element's name
      # @api public
      def initialize(name)
        # raise ArgumentError, "An Element doc needs to be initialize by passing a hash with a ':name' keyed entry." unless opts.is_a?(Hash) && opts.has_key?(:name)
        @name       = name
        @attributes = {}
      end

      # @param [String] name The name of the attribute described
      # @param [String] desc The description of the attribute
      # @api public
      def attribute(name, desc)
        @attributes[name] = desc
      end

    end # of ElementDoc

    # Namespaced param documentation
    #
    # @api public
    class NamespacedParam

      # @return [String, Symbol] The name of the namespaced, usually a symbol
      # @api public
      attr_reader :name

      # @return [Hash] The list of params within the namespace
      # @api public
      attr_reader :params

      # @api public
      def initialize(name)
        @name   = name
        @params = {}
      end

      # Sets the description/documentation of a specific namespaced param
      #
      # @return [String]
      # @api public
      def param(name, desc)
        @params[name] = desc
      end

    end

    # Initialize a Documentation object wrapping all the documentation aspect of the service.
    # The response documentation is a Documentation instance living inside the service documentation object.
    #
    # @api public
    def initialize
      @params_doc   = {}
      @examples     = []
      @elements     = []
      @namespaced_params = []
    end

    # Sets or returns the overall description
    #
    # @param [String] desc Service overall description
    # @api public
    # @return [String] The overall service description
    def overall(desc)
      if desc.nil?
        @desc
      else 
        @desc = desc
      end
    end

    # Sets the description/documentation of a specific param
    #
    # @return [String]
    # @api public
    def params(name, desc)
      @params_doc[name] = desc
    end
    alias_method :param, :params

    # Define a new namespaced param and yield it to the passed block
    # if available.
    #
    # @return [Array] the namespaced params
    # @api public
    def namespace(ns_name)
      new_ns_param = NamespacedParam.new(ns_name)
      if block_given?
        yield(new_ns_param)
      end
      @namespaced_params << new_ns_param
    end

    def response
      @response ||= Documentation.new
    end

    # Service usage example
    #
    # @param [String] desc Usage example.
    # @return [Array<String>] All the examples.
    # @api public
    def example(desc)
      @examples << desc
    end

    # Add a new element to the doc
    # currently only used for response doc
    #
    # @param [Hash] opts element's documentation options
    # @yield [ElementDoc] The new element doc.
    # @return [Array<ElementDoc>] 
    # @api public
    def element(opts={})
      element = ElementDoc.new(opts)
      yield(element)
      @elements << element
    end


  end # of Documentation
end
