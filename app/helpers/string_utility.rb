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

  def to_filesystems_compatible_filename(file_or_folder_name)
    file_or_folder_name.strip
                       .sub(/^[.-]*/, '')
                       .sub(/\.*$/, '')
                       .gsub(/[^\w',;. -]/, '_')
  end
end
