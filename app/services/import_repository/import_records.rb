module ImportRepository
  class ImportRecords
    def initialize(options)
      @temp_file = options.fetch(:temp_file)
      @repository = options.fetch(:repository)
      @mappings = options.fetch(:mappings)
      @session = options.fetch(:session)
      @user = options.fetch(:user)
    end

    def import!
      status = run_import_actions
      @temp_file.destroy
      status
    end

    private

    def run_import_actions
      @temp_file.file.open do |temp_file|
        @repository.import_records(
          SpreadsheetParser.open_spreadsheet(temp_file),
          @mappings,
          @user
        )
      end
    end

    def run_checks
      unless @mappings
        return {
          status: :error,
          errors:
            I18n.t('repositories.import_records.error_message.no_data_to_parse')
        }
      end
      unless @mappings.value?('-1')
        return {
          status: :error,
          errors:
            I18n.t('repositories.import_records.error_message.no_column_name')
        }
      end
      unless @temp_file
        return {
          status: :error,
          errors:
            I18n.t(
              'repositories.import_records.error_message.temp_file_not_found'
            )
        }
      end
      unless @temp_file.session_id == session.id
        return {
          status: :error,
          errors:
            I18n.t('repositories.import_records.error_message.session_expired')
        }
      end
    end
  end
end
