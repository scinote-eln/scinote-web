# frozen_string_literal: true

class UpdateTrimHtmlTagsFunction < ActiveRecord::Migration[5.2]
  def up
    execute(
      "CREATE OR REPLACE FUNCTION
        trim_html_tags(IN input TEXT, OUT output TEXT) AS $$
      SELECT regexp_replace(input, E'<[^>]*>', '', 'g');
      $$ LANGUAGE SQL;"
    )
  end
end
