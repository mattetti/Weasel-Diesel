# Include this module in WeaselDiesel
# to add response verification methods.
#
module JSONResponseVerification

  # Verifies the parsed body of a JSON response against the service's response description.
  #
  # @return [Array<TrueClass, FalseClass, Array<String>>] True/false and an array of errors.
  def verify(parsed_json_body)
    errors = [verify_element(parsed_json_body, response.nodes.first)]
    errors.flatten!
    [errors.empty?, errors]
  end

  alias :validate_hash_response :verify # backguard compatibility

  private

  # Recursively validates an element found when parsing a JSON.
  #
  # @param [Hash, Array, nil] el parsed JSON to be verified.
  # @param [WDSL::Response::Element] expected the reference element defined in the response description.
  # @param [TrueClass, FalseClass] verify_namespace if the nesting must be verified.
  # @return [Arrays<String>] errors the list of errors encountered while verifying.
  def verify_element(el, expected, verify_namespace=true)
    if expected.name && verify_namespace
      if verified_namespace?(el, expected.name)
        el = el[expected.name.to_s]
        verify_namespace = false
      else
        return something_is_missing_error(expected)
      end
    else
      verify_namespace = true
    end
    if el.nil?
      something_is_missing_error(expected)
    elsif el.is_a?(Array)
      verify_array(el, expected, verify_namespace)
    else
      verify_object(el, expected, verify_namespace)
    end
  end

  # Verifies hash corresponding to a JSON response against a given namespace
  #
  # @param [Array] array array to be verified.
  # @param [WDSL::Response::Element] expected the reference element defined in the response description.
  # @return [TrueClass, FalseClass] if the nesting name found is correct.
  def verified_namespace?(hash, expected_name)
    hash.respond_to?(:has_key?) && hash.has_key?(expected_name.to_s)
  end

  # Validates an array found when parsing a JSON.
  #
  # @param [Array] array array to be verified.
  # @param [WDSL::Response::Element] expected the reference element defined in the response description.
  # @return [Arrays<String>] errors the list of errors encountered while verifying.
  def verify_array(array, expected, verify_nesting)
    return wrong_type_error(array, expected.name, expected.type) unless expected.is_a?(WeaselDiesel::Response::Vector)
    expected = expected.elements && expected.elements.any? ? expected.elements.first : expected
    array.map{ |el| verify_element(el, expected, verify_nesting) }
  end

  # Validates a hash corresponding to a JSON object.
  #
  # @param [Hash] hash hash to be verified.
  # @param [WDSL::Response::Element] expected the reference element defined in the response description.
  # @return [Arrays<String>] errors the list of errors encountered while verifying.
  def verify_object(hash, expected, verify_nesting)
    [verify_attributes(hash, expected)] + [verify_objects(hash, expected)]
  end

  # Validates the objects found in a hash corresponding to a JSON object.
  #
  # @param [Hash] hash hash representing a JSON object whose internal objects will be verified.
  # @param [WDSL::Response::Element] expected the reference element defined in the response description.
  # @return [Arrays<String>] errors the list of errors encountered while verifying.
  def verify_objects(hash, expected)
    return [] unless expected.objects
    expected.objects.map do |expected|
      found = hash[expected.name.to_s]
      null_allowed = expected.respond_to?(:opts) && expected.opts[:null]
      if found.nil?
        null_allowed ? [] : something_is_missing_error(expected)
      else
        verify_element(found, expected, false) # don't verify nesting
      end
    end
  end

  # Validates the attributes found in a hash corresponding to a JSON object.
  #
  # @param [Hash] hash hash whose attributes will be verified.
  # @param [WDSL::Response::Element] expected the reference element defined in the response description.
  # @return [Arrays<String>] errors the list of errors encountered while verifying.
  def verify_attributes(hash, expected)
    return [] unless expected.attributes
    expected.attributes.map{ |a| verify_attribute_value(hash[a.name.to_s], a) }
  end

  # Validates a value against a found in a hash corresponding to a JSON object.
  #
  # @param [value] value value to be verified.
  # @param [WDSL::Response::Attribute] expected the reference element defined in the response description.
  # @return [Arrays<String>] errors the list of errors encountered while verifying.
  def verify_attribute_value(value, attribute)
    null_allowed = attribute.respond_to?(:opts) && !!attribute.opts[:null]
    if value.nil?
      null_allowed ? [] : wrong_type_error(value, attribute.name, attribute.type)
    else
      type = attribute.type
      return [] if type.to_sym == :string
      rule = ParamsVerification.type_validations[attribute.type.to_sym]
      puts "Don't know how to validate attributes of type #{type}" if rule.nil?
      (rule.nil? || value.to_s =~ rule) ? [] : wrong_type_error(value, attribute.name, attribute.type)
    end
  end

  # Returns an error message reporting that an expected data hasn't been found in the JSON response.
  #
  # @param [WDSL::Response::Element, WDSL::Response::Attribute] expected missing data.
  # @return [String] error message
  def something_is_missing_error(expected)
    "#{expected.name || 'top level'} Node/Object/Element is missing"
  end

  # Returns an error message reporting that a value doesn't correspond to an expected data type.
  #
  # @param [value] value which doesn't correspond to the expected type.
  # @param [data_name] data_name name of the data containing the value.
  # @param [expected_type] expected type.
  # @return [String] error message
  def wrong_type_error(value, data_name, expected_type)
    "#{data_name} was of wrong type, expected #{expected_type} and the value was #{value}"
  end

end