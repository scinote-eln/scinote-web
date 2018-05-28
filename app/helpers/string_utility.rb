module StringUtility
  def ellipsize(
    string,
    minimum_length = Constants::MAX_NAME_TRUNCATION,
    edge_length = Constants::MAX_EDGE_LENGTH
  )
    length = string.length
    return string if length < minimum_length || length <= edge_length * 2
    edge = '.' * edge_length
    mid_length = length - edge_length * 2
    string.gsub(/(#{edge}).{#{mid_length},}(#{edge})/, '\1...\2')
  end
end
