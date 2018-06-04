class PostcodeValidator < ActiveModel::EachValidator
  PATTERN  = /\AJE[1-5][0-9][A-Z][A-Z]\Z/i

  def validate_each(record, attribute, value)
    unless value.to_s =~ PATTERN
      record.errors.add(attribute, (options[:message] || :invalid))
    end
  end
end
