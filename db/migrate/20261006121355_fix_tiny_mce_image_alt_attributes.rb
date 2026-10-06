# frozen_string_literal: true

class FixTinyMceImageAltAttributes < ActiveRecord::Migration[7.2]
  IMG_TAG_REGEX = /<img\b[^>]*>/i
  TOKEN_REGEX = /\bdata-mce-token=(["'])([0-9a-zA-Z]+)\1/i
  ALT_REGEX = /\balt=(["'])description-([0-9a-zA-Z]*)\1/i

  def up
    [StepText, ResultText].each do |model|
      model.where("text LIKE '%data-mce-token%' AND text LIKE '%description-%'")
           .select(:id, :text)
           .find_each do |record|
        fixed_text = fix_alt_attributes(record.text)
        next if fixed_text == record.text

        record.update_column(:text, fixed_text)
      end
    end
  end

  def down
    # Data fix only, nothing to revert
  end

  private

  def fix_alt_attributes(text)
    text.gsub(IMG_TAG_REGEX) do |img_tag|
      token = img_tag[TOKEN_REGEX, 2]
      alt_match = img_tag.match(ALT_REGEX)
      next img_tag if token.blank? || alt_match.nil? || alt_match[2] == token

      img_tag.sub(ALT_REGEX, "alt=#{alt_match[1]}description-#{token}#{alt_match[1]}")
    end
  end
end
