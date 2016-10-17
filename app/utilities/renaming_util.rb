module RenamingUtil

  # Rename the given record in memory (without saving it!)
  # by trying various combinations of appending number/s to the
  # end of its name (provided by the name column).
  #
  # WARNING: Other record fields MUST BE valid before calling
  # this function, as it uses the ActiveRecord.valid? method.
  #
  # WARNING: The maximum length validations on the provided name_col
  # MUST BE at least 10 characters, otherwise this function can
  # stir some odd behaviour.
  def rename_record(record, name_col)
    clazz = record.class
    prev_name = record[name_col]

    # Skip already valid records
    if record.valid?
      return
    end

    # Get the max. length validation, if it exist
    # IF MAX_LENGTH IS VERY LOW, this code here could
    # potentially cause trouble. Let's hope max_length is always 10+
    max_length = Constants::INFINITY
    clazz
    .validators_on(name_col)
    .select{ |v| v.class == ActiveModel::Validations::LengthValidator }
    .each do |v|
      max = v.options[:maximum]
      if max.present? && max < max_length
        max_length = max
      end
    end

    # First, check if name is simply too long
    if prev_name.length > max_length then
      record[name_col] = prev_name[0..(max_length - 4)] + "..."

      if record.valid?
        return
      end
    end

    # Now, start renaming (we try 100 tries)
    cntr = 0
    while (record.invalid? && cntr < 100) do
      cntr += 1
      suffix = " (#{cntr})"
      if prev_name.length + suffix.length > max_length
        record[name_col] =
          prev_name[0..(max_length - 4 - suffix.length)] + suffix
      else
        record[name_col] = prev_name + suffix
      end
    end

    return record.valid?
  end

end
