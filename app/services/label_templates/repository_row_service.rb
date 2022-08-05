# frozen_string_literal: true

module LabelTemplates
  class RepositoryRowService
    class UnsupportedKeyError < StandardError; end

    class ColumnNotFoundError < StandardError; end

    def initialize(label_template, repository_row)
      @label_template = label_template
      @repository_row = repository_row
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
      when /^COLUMN_\[(.*)\]/
        name = Regexp.last_match(1)
        repository_cell = @repository_row.repository_cells.joins(:repository_column).find_by(
          repository_columns: { name: name }
        )

        unless repository_cell
          raise UnsupportedKeyError, I18n.t('label_templates.repository_row.errors.column_not_found', column: name)
        end

        repository_cell.value.formatted
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
