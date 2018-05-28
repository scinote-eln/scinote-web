module HashUtil

  def deep_stringify_values(obj, include_arrays = true)
    if obj.is_a?(Hash)
      obj.map { |k, v| [k, deep_stringify_values(v, include_arrays)] }.to_h
    elsif include_arrays && obj.is_a?(Array)
      obj.map { |i| deep_stringify_values(i, include_arrays) }
    else
      obj.to_s
    end
  end
  module_function :deep_stringify_values

  def deep_stringify_keys_and_values(obj, include_arrays = true)
    deep_stringify_values(obj, include_arrays).deep_stringify_keys
  end
  module_function :deep_stringify_keys_and_values
end