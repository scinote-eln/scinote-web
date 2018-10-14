# frozen_string_literal: true

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

  # Convert string to filesystem compatible file/folder name
  def to_filesystem_name(name)
    # Handle reserved directories
    if name == '..'
      return '__'
    elsif name == '.'
      return '_'
    end

    # Truncate and replace reserved characters
    name = name[0, Constants::EXPORTED_FILENAME_TRUNCATION_LENGTH]
           .gsub(%r{[*":<>?/\\|~]}, '_')

    # Remove control characters
    name = name.chars.map(&:ord).select { |s| (s > 31 && s < 127) || s > 127 }
               .pack('U*')

    # Remove leading hyphens, trailing dots/spaces
    name.gsub(/^-|\.+$| +$/, '_')
  end
end
