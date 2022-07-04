# frozen_string_literal: true

module LabelTemplates
  class RepositoryRowService
    class RepositoryMismatchError < StandardError; end

    class UnsupportedKeyError < StandardError; end

    def initialize(label_template, repository_row)
      @label_template = label_template
      @repository_row = repository_row

      if label_template.repository != repository_row.repository
        raise RepositoryMismatchError, I18n.t('label_templates.repository_row.errors.repository_mismatch')
      end
    end

    def render
      keys = @label_template.content.scan(/(?<=\{\{).*?(?=\}\})/).uniq

      keys.reduce(@label_template.content.dup) do |rendered_content, key|
        rendered_content.gsub!(/\{\{#{key}\}\}/, fetch_value(key))
      end
    end

    private

    def fetch_value(key)
      case key
      when /^COLUMN_(\d+)/
        @repository_row.repository_cells.find_by!(
          repository_column_id: Regexp.last_match(1)
        ).value.formatted
      when 'ITEM_ID'
        @repository_row.code
      when 'NAME'
        @repository_row.name
      when 'ADDED_BY'
        @repository_row.created_by.full_name
      when 'ADDED_ON'
        @repository_row.created_at.to_s
      else
        raise UnsupportedKeyError, I18n.t('label_templates.repository_row.errors.unsupported_key', key: key)
      end
    end
  end
end
