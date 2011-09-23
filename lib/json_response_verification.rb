# include this module in WSDSL
# to add response verification methods.
#
module JSONResponseVerification

  # Validates a hash against the service's response description.
  #
  # @return [Array<TrueClass, FalseClass, Array<String>>] True/false and an array of errors.
  def validate_hash_response(hash)
    errors = []
    # nodes without the arrays
    response.nodes.each do |node|
      if node.name
        # Verify that the named node exists in the hash
        unless hash.has_key?(node.name.to_s)
          errors << json_response_error(node, hash) 
          return [false, errors]
        end
      end
      errors += validate_hash_against_template_node(hash, node)
    end

    [errors.empty?, errors]
  end

  private

  # Recursively validates a hash representing a json response.
  #
  # @param [Hash>] hash the hash to verify.
  # @param [WDSL::Response::Element] node the reference element defined in the response description.
  # @param [TrueClass, FalseClass] nested if the node/hash to verify is nested or not. If nested, the method expects to get the subhash 
  #   & won't verify that the name exists since it was done a level higher.
  # @param [Arrays<String>] errors the list of errors encountered while verifying.
  # @param []
  # @return [TrueClass, FalseClass]
  def validate_hash_against_template_node(hash, node, nested=false, errors=[], array_item=false)
    if hash.nil?
      errors << json_response_error(node, hash)
      return errors
    end

    if node.name && !nested
      if hash.has_key?(node.name.to_s)
        subhash = hash[node.name.to_s]
      else
        errors << json_response_error(node, hash)
      end
    end

    subhash ||= hash
    if node.is_a?(WSDSL::Response::Vector) && !array_item
      errors << json_response_error(node, subhash, true) unless subhash.is_a?(Array)
      subhash.each do |obj|
        validate_hash_against_template_node(obj, node, true, errors, true)
      end
    else
      node.properties.each do |prop|
        if !array_item && !subhash.has_key?(prop.name.to_s)
          errors << json_response_error(prop, subhash)
        end
        errors << json_response_error(prop, subhash, true) unless valid_hash_type?(subhash, prop)
      end

      node.objects.each do |obj|
        # recursive call
        validate_hash_against_template_node(subhash[obj.name.to_s], obj, true, errors)
      end if node.objects
    end

    errors
  end

  def json_response_error(el_or_attr, hash, type_error=false)
    if el_or_attr.is_a?(WSDSL::Response::Element)
      "#{el_or_attr.name || 'top level'} Node/Object/Element is missing"
    elsif type_error
      "#{el_or_attr.name || el_or_attr.inspect} was of wrong type"
    else
      "#{el_or_attr.name || el_or_attr.inspect} is missing in #{hash.inspect}"
    end
  end

  def valid_hash_type?(hash, prop_template)
    type = prop_template.type
    return true if type.nil?
    rule = ParamsVerification.type_validations[type.to_sym]
    return true if rule.nil?
    attribute = hash[prop_template.name.to_s]
    attribute.to_s =~ rule
  end

end
