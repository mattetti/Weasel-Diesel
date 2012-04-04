class WeaselDiesel
  # Service params class letting you define param rules.
  # Usually not initialized directly but accessed via the service methods.
  #
  # @see WeaselDiesel#params
  #
  # @api public
  class Params  

    # Params usually have a few rules used to validate requests.
    # Rules are not usually initialized directly but instead via
    # the service's #params accessor.
    #
    # @api public
    class Rule

      # @return [Symbol, String] name The name of the param the rule applies to.
      # @api public
      attr_reader :name

      # @return [Hash] options The rule options.
      # @option options [Symbol] :in A list of acceptable values.
      # @option options [Symbol] :options A list of acceptable values.
      # @option options [Symbol] :default The default value of the param.
      # @option options [Symbol] :minvalue The minimum acceptable value.
      # @option options [Symbol] :maxvalue The maximim acceptable value.
      # @api public
      attr_reader :options


      # @param [Symbol, String] name 
      #   The param's name
      # @param [Hash] opts The rule options
      # @option opts [Symbol] :in A list of acceptable values.
      # @option opts [Symbol] :options A list of acceptable values.
      # @option opts [Symbol] :default The default value of the param.
      # @option opts [Symbol] :minvalue The minimum acceptable value.
      # @option opts [Symbol] :maxvalue The maximim acceptable value.
      # @api public
      def initialize(name, opts = {})
        @name    = name
        @options = opts
      end

      # The namespace used if any
      #
      # @return [NilClass, String]
      # @api public
      def namespace
        @options[:space_name]
      end

      # Converts the rule into a hash with its name and options.
      #
      # @return [Hash]
      def to_hash
        {:name => name, :options => options}
      end

    end # of Rule

    # The namespace used if any
    #
    # @return [String]
    # @api public
    attr_reader :space_name

    # @param [Hash] opts The params options
    # @option opts [:symbol] :space_name Optional namespace.
    # @api public
    def initialize(opts={})
      @space_name = opts[:space_name]
    end

    # Defines a new param and add it to the optional or required list based
    # the passed options.
    # @param [Symbol] type
    #   The type of param
    #
    # @param [Symbol, String] name
    #   The name of the param
    #
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Declaring an integer service param called id
    #   service.param(:id, :integer, :default => 9999, :in => [0, 9999])
    #
    # @return [Array] the typed list of params (required or optional)
    # @api public]
    def param(type, name, options={})
      options[:type] = type
      options[:space_name] = options[:space_name] || space_name
      if options.delete(:required)
        list_required << Rule.new(name, options)
      else
        list_optional << Rule.new(name, options)
      end
    end

    # @group Params defintition DSL (accept_param style)

    # Defines a new string param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def string(name, options={})
      param(:string, name, options)
    end

    # Defines a new integer param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def integer(name, options={})
      param(:integer, name, options)
    end

    # Defines a new float param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def float(name, options={})
      param(:float, name, options)
    end

    # Defines a new decimal param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def decimal(name, options={})
      param(:decimal, name, options)
    end

    # Defines a new boolean param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def boolean(name, options={})
      param(:boolean, name, options)
    end

    # Defines a new datetime param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def datetime(name, options={})
      param(:datetime, name, options)
    end

    # Defines a new text param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def text(name, options={})
      param(:text, name, options)
    end

    # Defines a new binary param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def binary(name, options={})
      param(:binary, name, options)
    end

    # Defines a new array param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Array<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def array(name, options={})
      param(:array, name, options)
    end

    # Defines a new file param and add it to the required or optional list
    #
    # @param [String] name
    #   The name of the param
    # @param [Hash] options
    #   A hash representing the param settings
    #
    # @example Defining a string service param named type which has various options.
    #    service.param.string  :type, :in => LeaderboardType.names, :default => LeaderboardType::LIFETIME
    #
    # @api public
    # @return [Arrays<WeaselDiesel::Params::Rule>] 
    #   List of optional or required param rules depending on the new param rule type
    def file(name, options={})
      param(:file, name, options)
    end

    # @group param setters based on the state (required or optional)

    # Defines a new required param
    #
    # @param [Symbol, String] param_name
    #   The name of the param to define
    # @param [Hash] opts
    #    A hash representing the required param, the key being the param name name
    #    and the value being a hash of options.
    #
    # @example Defining a required service param called 'id' of `Integer` type
    #   service.params.required :id, :type => 'integer', :default => 9999
    #
    # @return [Array<WeaselDiesel::Params::Rule>] The list of required rules
    #
    # @api public
    def required(param_name, opts={})
      # # support for when a required param doesn't have any options
      # unless opts.respond_to?(:each_pair)
      #   opts = {opts => nil}
      # end
      # # recursive rule creation
      # if opts.size > 1
      #   opts.each_pair{|k,v| requires({k => v})}
      # else
      list_required << Rule.new(param_name, opts)
      # end
    end

    # Defines a new optional param rule
    #
    # @param [Symbol, String] param_name
    #   The name of the param to define
    # @param [Hash] opts
    #    A hash representing the required param, the key being the param name name
    #    and the value being a hash of options.
    #
    # @example Defining an optional service param called 'id' of `Integer` type
    #   service.params.optional :id, :type => 'integer', :default => 9999
    #
    # @return [Array<WeaselDiesel::Params::Rule>] The list of optional rules
    # @api public
    def optional(param_name, opts={})
      # # recursive rule creation
      # if opts.size > 1
      #   opts.each_pair{|k,v| optional({k => v})}
      # else
      list_optional << Rule.new(param_name, opts)
      # end
    end

    # @group params accessors per status (required or optional)

    # Returns an array of all the required params
    #
    # @return [Array<WeaselDiesel::Params::Rule>] The list of required rules
    # @api public
    def list_required
      @required ||= []
    end

    # Returns an array of all the optional params
    #
    # @return [Array<WeaselDiesel::Params::Rule>] all the optional params
    # @api public
    def list_optional
      @optional ||= []
    end

    # @endgroup

    # Defines a namespaced param
    #
    # @yield [Params] the newly created namespaced param
    # @return [Array<WeaselDiesel::Params>] the list of all the namespaced params
    # @api public
    def namespace(name)
      params = Params.new(:space_name => name)
      yield(params) if block_given?
      namespaced_params << params unless namespaced_params.include?(params)
    end

    # Returns the namespaced params
    #
    # @return [Array<WeaselDiesel::Params>] the list of all the namespaced params
    # @api public
    def namespaced_params
      @namespaced_params ||= []
    end

    # Returns the names of the first level expected params
    #
    # @return [Array<WeaselDiesel::Params>]
    # @api public
    def param_names
      first_level_expected_params = (list_required + list_optional).map{|rule| rule.name.to_s}
      first_level_expected_params += namespaced_params.map{|r| r.space_name.to_s}
      first_level_expected_params
    end

  end # of Params
end
