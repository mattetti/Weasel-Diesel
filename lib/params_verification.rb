require 'erb' # used to sanitize the error message and avoid XSS attacks

# ParamsVerification module.
# Written to verify a service params without creating new objects.
# This module is used on all requests requiring validation and therefore performance
# security and maintainability are critical.
#
# @api public
module ParamsVerification
  
  class ParamError        < StandardError; end #:nodoc
  class NoParamsDefined   < ParamError; end #:nodoc
  class MissingParam      < ParamError; end #:nodoc
  class UnexpectedParam   < ParamError; end #:nodoc
  class InvalidParamType  < ParamError; end #:nodoc
  class InvalidParamValue < ParamError; end #:nodoc
  
  # An array of validation regular expressions.
  # The array gets cached but can be accessed via the symbol key.
  #
  # @return [Hash] An array with all the validation types as keys and regexps as values.
  # @api public
  def self.type_validations
    @type_validations ||= { :integer  => /^-?\d+$/,
                            :float    => /^-?(\d*\.\d+|\d+)$/,
                            :decimal  => /^-?(\d*\.\d+|\d+)$/,
                            :datetime => /^[-\d:T\s\+]+$/,  # "T" is for ISO date format
                            :boolean  => /^(1|true|TRUE|T|Y|0|false|FALSE|F|N)$/,
                            #:array    => /,/
                          }
  end
  
  # Validation against each required WeaselDiesel::Params::Rule
  # and returns the potentially modified params (with default values)
  # 
  # @param [Hash] params The params to verify (incoming request params)
  # @param [WeaselDiesel::Params] service_params A Playco service param compatible object listing required and optional params 
  # @param [Boolean] ignore_unexpected Flag letting the validation know if unexpected params should be ignored
  #
  # @return [Hash]
  #   The passed params potentially modified by the default rules defined in the service.
  #
  # @example Validate request params against a service's defined param rules
  #   ParamsVerification.validate!(request.params, @service.defined_params)
  # 
  # @api public
  def self.validate!(params, service_params, ignore_unexpected=false)
    
    # Verify that no garbage params are passed, if they are, an exception is raised.
    # only the first level is checked at this point
    unless ignore_unexpected
      unexpected_params?(params, service_params.param_names)
    end
    
    # dupe the params so we don't modify the passed value
    updated_params = params.dup
    # Required param verification
    service_params.list_required.each do |rule|
      updated_params = validate_required_rule(rule, updated_params)
    end
    
    # Set optional defaults if any optional
    service_params.list_optional.each do |rule|
      updated_params = validate_optional_rule(rule, updated_params)
    end
    
    # check the namespaced params
    service_params.namespaced_params.each do |param|
      param.list_required.each do |rule|
        updated_params = validate_required_rule(rule, updated_params, param.space_name.to_s)
      end
      param.list_optional.each do |rule|
        updated_params = validate_optional_rule(rule, updated_params, param.space_name.to_s)
      end
    end
    
    # verify nested params, only 1 level deep tho
    params.each_pair do |key, value|
      if value.is_a?(Hash)
        namespaced = service_params.namespaced_params.find{|np| np.space_name.to_s == key.to_s}
        raise UnexpectedParam, "Request included unexpected parameter: #{ERB::Util.html_escape(key)}" if namespaced.nil?
        unexpected_params?(params[key], namespaced.param_names)
      end
    end
    
    updated_params
  end
  
  
  private
  
  # Validates a required rule against a list of params passed.
  #
  #
  # @param [WeaselDiesel::Params::Rule] rule The required rule to check against.
  # @param [Hash] params The request params.
  # @param [String] namespace Optional param namespace to check the rule against.
  #
  # @return [Hash]
  #   A hash representing the potentially modified params after going through the filter.
  #
  # @api private
  def self.validate_required_rule(rule, params, namespace=nil)
    param_name  = rule.name.to_s
    param_value, namespaced_params = extract_param_values(params, param_name, namespace)

    # Checks presence
    if !(namespaced_params || params).keys.include?(param_name)
      raise MissingParam, "'#{rule.name}' is missing - passed params: #{params.inspect}."
    end

    updated_param_value, updated_params = validate_and_cast_type(param_value, param_name, rule.options[:type], params, namespace)

    # check for nulls in params that don't allow them
    if !valid_null_param?(param_name, updated_param_value, rule)
      raise InvalidParamValue, "Value for parameter '#{param_name}' cannot be null - passed params: #{updated_params.inspect}."
    elsif updated_param_value
      value_errors = validate_ruled_param_value(param_name, updated_param_value, rule)
      raise InvalidParamValue, value_errors.join(', ') if value_errors
    end

    updated_params
  end


  # Validates that an optional rule is respected.
  # If the rule contains default values, the params might be updated.
  #
  # @param [#WeaselDiesel::Params::Rule] rule The optional rule
  # @param [Hash] params The request params
  # @param [String] namespace An optional namespace
  #
  # @return [Hash] The potentially modified params
  # 
  # @api private
  def self.validate_optional_rule(rule, params, namespace=nil)
    param_name  = rule.name.to_s
    param_value, namespaced_params = extract_param_values(params, param_name, namespace)

    if param_value && !valid_null_param?(param_name, param_value, rule)
      raise InvalidParamValue, "Value for parameter '#{param_name}' cannot be null if passed - passed params: #{params.inspect}."
    end

    # Use a default value if one is available and the submitted param value is nil
    if param_value.nil? && rule.options[:default]
      param_value = rule.options[:default]
      if namespace
        params[namespace] ||= {}
        params[namespace][param_name] = param_value
      else
        params[param_name] = param_value
      end
    end

    updated_param_value, updated_params = validate_and_cast_type(param_value, param_name, rule.options[:type], params, namespace)
    value_errors = validate_ruled_param_value(param_name, updated_param_value, rule) if updated_param_value
    raise InvalidParamValue, value_errors.join(', ') if value_errors

    updated_params
  end


  # Validates the param value against the rule and cast the param in the appropriate type.
  # The modified params containing the cast value is returned along the cast param value.
  #
  # @param [Object] param_value The value to validate and cast.
  # @param [String] param_name The name of the param we are validating.
  # @param [Symbol] type The expected object type.
  # @param [Hash] params The params that might need to be updated.
  # @param [String, Symbol] namespace The optional namespace used to access the `param_value`
  #
  # @return [Array<Object, Hash>] An array containing the param value and 
  #   a hash representing the potentially modified params after going through the filter.
  #
  def self.validate_and_cast_type(param_value, param_name, rule_type, params, namespace=nil)
    # checks type & modifies params if needed
    if rule_type && param_value
      verify_cast(param_name, param_value, rule_type)
      param_value = type_cast_value(rule_type, param_value)
      # update the params hash with the type cast value
      if namespace
        params[namespace] ||= {}
        params[namespace][param_name] = param_value
      else
        params[param_name] = param_value
      end
    end
    [param_value, params]
  end


  # Validates a value against a few rule options.
  #
  # @return [NilClass, Array<String>] Returns an array of error messages if an option didn't validate.
  def self.validate_ruled_param_value(param_name, param_value, rule)

    # checks the value against a whitelist style 'in'/'options' list
    if rule.options[:options] || rule.options[:in]
      choices = rule.options[:options] || rule.options[:in]
      unless param_value.is_a?(Array) ? (param_value & choices == param_value) : choices.include?(param_value)
        errors ||= []
        errors << "Value for parameter '#{param_name}' (#{param_value}) is not in the allowed set of values."
      end
    end

    # enforces a minimum numeric value
    if rule.options[:min_value]
      min = rule.options[:min_value]
      if param_value.to_i < min
        errors ||= []
        errors << "Value for parameter '#{param_name}' ('#{param_value}') is lower than the min accepted value (#{min})."
      end
    end

    # enforces a maximum numeric value
    if rule.options[:max_value]
      max = rule.options[:max_value]
      if param_value.to_i > max
        errors ||= []
        errors << "Value for parameter '#{param_name}' ('#{param_value}') is higher than the max accepted value (#{max})."
      end
    end

    # enforces a minimum string length
    if rule.options[:min_length]
      min = rule.options[:min_length]
      if param_value.to_s.length < min
        errors ||= []
        errors << "Length of parameter '#{param_name}' ('#{param_value}') is shorter than the min accepted value (#{min})."
      end
    end

    # enforces a maximum string length
    if rule.options[:max_length]
      max = rule.options[:max_length]
      if param_value.to_s.length > max
        errors ||= []
        errors << "Length of parameter '#{param_name}' ('#{param_value}') is longer than the max accepted value (#{max})."
      end
    end

    errors
  end

  # Extract the param value and the namespaced params
  # based on a passed namespace and params
  #
  # @param [Hash] params The passed params to extract info from.
  # @param [String] param_name The param name to find the value.
  # @param [NilClass, String] namespace the params' namespace.
  # @return [Array<Object, String>]
  #
  # @api private
  def self.extract_param_values(params, param_name, namespace=nil)
    # Namespace check
    if namespace == '' || namespace.nil?
      [params[param_name], nil]
    else
      # puts "namespace: #{namespace} - params #{params[namespace].inspect}"
      namespaced_params = params[namespace]
      if namespaced_params
        [namespaced_params[param_name], namespaced_params]
      else
        [nil, namespaced_params]
      end
    end
  end
  
  
  def self.unexpected_params?(params, param_names)
    # Raise an exception unless no unexpected params were found
    unexpected_keys = (params.keys - param_names)
    unless unexpected_keys.empty?
      raise UnexpectedParam, "Request included unexpected parameter(s): #{unexpected_keys.map{|k| ERB::Util.html_escape(k)}.join(', ')}"
    end
  end
  
  
  def self.type_cast_value(type, value)
    return value if value == nil
    case type
    when :integer
      value.to_i
    when :float, :decimal
      value.to_f
    when :string
      value.to_s
    when :boolean
      if value.is_a? TrueClass
        true
      elsif value.is_a? FalseClass
        false
      else
        case value.to_s
        when /^(1|true|TRUE|T|Y)$/
          true
        when /^(0|false|FALSE|F|N)$/
          false
        else
          raise InvalidParamValue, "Could not typecast boolean to appropriate value"
        end
      end
    # An array type is a comma delimited string, we need to cast the passed strings.
    when :array
      value.respond_to?(:split) ? value.split(',') : value
    when :binary, :file
      value
    else
      value
    end
  end
  
  # Checks that the value's type matches the expected type for a given param. If a nil value is passed
  # the verification is skipped.
  #
  # @param [Symbol, String] Param name used if the verification fails and that an error is raised.
  # @param [NilClass, #to_s] The value to validate.
  # @param [Symbol] The expected type, such as :boolean, :integer etc...
  # @raise [InvalidParamType] Custom exception raised when the validation isn't found or the value doesn't match.
  #
  # @return [NilClass]
  # @api public
  def self.verify_cast(name, value, expected_type)
    return if value == nil
    validation = ParamsVerification.type_validations[expected_type.to_sym]
    unless validation.nil? || value.to_s =~ validation
      raise InvalidParamType, "Value for parameter '#{name}' (#{value}) is of the wrong type (expected #{expected_type})"
    end
  end

  # Checks that a param explicitly set to not be null is present.
  # if 'null' is found in the ruleset and set to 'false' (default is 'true' to allow null),
  # then confirm that the submitted value isn't nil or empty
  # @param [String] param_name The name of the param to verify.
  # @param [NilClass, String, Integer, TrueClass, FalseClass] param_value The value to check.
  # @param [WeaselDiesel::Params::Rule] rule The rule to check against.
  #
  # @return [Boolean] true if the param is valid, false otherwise
  def self.valid_null_param?(param_name, param_value, rule)
    if rule.options.has_key?(:null) && rule.options[:null] == false
      if rule.options[:type] && rule.options[:type] == :array
        return false if param_value.nil? || (param_value.respond_to?(:split) && param_value.split(',').empty?)
      else
        return false if param_value.nil? || param_value == ''
      end
    end
    true
  end

  
end
