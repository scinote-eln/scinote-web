# frozen_string_literal: true

module LabelTemplates
  class RepositoryRowService
    class UnsupportedKeyError < StandardError; end

    class ColumnNotFoundError < StandardError; end

    class LogoNotFoundError < StandardError; end

    MAX_PRINTABLE_ITEM_NAME_LENGTH = 64

    def initialize(label_template, repository_row, print_mode=false)
      @label_template = label_template
      @repository_row = repository_row
      @print_mode = print_mode
      @repository_columns = RepositoryColumn.where(repository_id: @repository_row.repository_id).pluck(:name)
    end

    def render
      keys = @label_template.content.scan(/(?<=\{\{).*?(?=\}\})/).uniq

      keys.reduce(@label_template.content.dup) do |rendered_content, key|
        rendered_content.gsub!(/\{\{#{key}\}\}/, fetch_value(key))
      rescue ColumnNotFoundError, LogoNotFoundError => e
        raise e unless @print_mode

        rendered_content
      end
    end

    private

    def fetch_custom_column_value(name)
      repository_cell = @repository_row.repository_cells.joins(:repository_column).find_by(
        repository_columns: { name: name }
      )
      return '' unless repository_cell

      if repository_cell.value_type == 'RepositoryStatusValue'
        repository_cell.value.formatted_status
      else
        repository_cell.value.formatted
      end
    end

    def fetch_value(key)
      case key
      when /^c_(.*)/
        name = Regexp.last_match(1)
        unless @repository_columns.include?(name)
          raise ColumnNotFoundError, I18n.t('label_templates.repository_row.errors.column_not_found')
        end

        return '' unless @print_mode

        fetch_custom_column_value(name)
      when 'ITEM_ID'
        @repository_row.code
      when 'NAME'
        @repository_row.name.truncate(MAX_PRINTABLE_ITEM_NAME_LENGTH)
      when 'ADDED_BY'
        @repository_row.created_by.full_name
      when 'ADDED_ON'
        @repository_row.created_at.to_s
      when 'LOGO'
        logo
      else
        raise ColumnNotFoundError, I18n.t('label_templates.repository_row.errors.column_not_found')
      end
    end

    def logo
      raise LogoNotFoundError, I18n.t('label_templates.repository_row.errors.logo_not_supported')
    end
  end
end
