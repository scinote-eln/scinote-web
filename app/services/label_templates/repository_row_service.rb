# frozen_string_literal: true
module LabelTemplates
  class ColumnNotFoundError < StandardError; end
  class LogoNotFoundError < StandardError; end
  class LogoParamsError < StandardError; end

  class RepositoryRowService

    MAX_PRINTABLE_ITEM_NAME_LENGTH = 64

    def initialize(label_template, repository_row)
      @label_template = label_template
      @repository_row = repository_row
    end

    def render
      errors = []
      keys = @label_template.content.scan(/(?<=\{\{).*?(?=\}\})/).uniq
      label = keys.reduce(@label_template.content.dup) do |rendered_content, key|
        rendered_content.gsub!(Regexp.new(Regexp.escape("{{#{key}}}")), fetch_value(key))
      rescue LabelTemplates::ColumnNotFoundError,
             LabelTemplates::LogoNotFoundError,
             LabelTemplates::LogoParamsError => e
        errors.push(e)
        rendered_content
      end

      { label: label, error: errors }
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
        unless @repository_row.repository_columns.find_by(name: name)
          raise LabelTemplates::ColumnNotFoundError, I18n.t('label_templates.repository_row.errors.column_not_found')
        end

        fetch_custom_column_value(name)
      when 'ITEM_ID'
        @repository_row.code
      when 'NAME'
        @repository_row.name.truncate(MAX_PRINTABLE_ITEM_NAME_LENGTH)
      when 'ADDED_BY'
        @repository_row.created_by.full_name
      when 'ADDED_ON'
        I18n.l(@repository_row.created_at, format: :full)
      when /^LOGO/
        logo(key)
      else
        raise LabelTemplates::ColumnNotFoundError, I18n.t('label_templates.repository_row.errors.column_not_found')
      end
    end

    def logo(_key)
      raise LabelTemplates::LogoNotFoundError, I18n.t('label_templates.repository_row.errors.logo_not_supported')
    end
  end
end
