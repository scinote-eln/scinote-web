# frozen_string_literal: true

module RepositoryRows
  class MyModuleAssigningService
    extend Service

    attr_reader :repository, :my_module, :user, :params, :assigned_rows_names, :errors

    def initialize(my_module:, repository:, user:, params:)
      @my_module = my_module
      @repository = repository
      @user = user
      @params = params
      @assigned_rows_names = []
      @errors = {}
    end

    def call
      return self unless valid?

      downstream_modules = []
      downstream_records = {}

      ActiveRecord::Base.transaction do
        unassigned_rows = @repository.repository_rows
                                     .joins("LEFT OUTER JOIN my_module_repository_rows "\
                                            "ON repository_rows.id = my_module_repository_rows.repository_row_id "\
                                            "AND my_module_repository_rows.my_module_id = #{@my_module.id.to_i}")
                                     .where(my_module_repository_rows: { id: nil })
                                     .where(id: @params[:selected_rows])

        unassigned_rows.find_each do |repository_row|
          MyModuleRepositoryRow.create!(my_module: @my_module, repository_row: repository_row, assigned_by: @user)
          @assigned_rows_names << repository_row.name

          next unless @params[:downstream] == 'true'

          unassigned_downstream_modules = @my_module.downstream_modules
                                                    .left_outer_joins(:my_module_repository_rows)
                                                    .where.not(my_module_repository_rows: { repository_row: record })

          unassigned_downstream_modules.each do |downstream_module|
            next if my_module.repository_rows.include?(repository_row)

            downstream_records[my_module.id] = [] unless downstream_records[downstream_module.id]
            MyModuleRepositoryRow.create!(
              my_module: downstream_module,
              repository_row: repository_row,
              assigned_by: @user
            )
            downstream_records[downstream_module.id] << repository_row.name
            downstream_modules.push(downstream_module)
          end

          if @assigned_rows_names.present?
            @assigned_rows_names.uniq!
            log_activity(@my_module,
                         repository: @repository.id,
                         record_names: @assigned_rows_names.join(', '))
            downstream_modules.uniq.each do |downstream_module|
              log_activity(downstream_module,
                           repository: @repository.id,
                           record_names: downstream_records[my_module.id].join(', '))
            end
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[e.record.class.name.underscore] = e.record.errors.full_messages
        raise ActiveRecord::Rollback
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def log_activity(my_module = nil, message_items = {})
      message_items = { my_module: my_module.id }.merge(message_items)

      Activities::CreateActivityService
        .call(activity_type: :assign_repository_record,
              owner: current_user,
              team: my_module.experiment.project.team,
              project: my_module.experiment.project,
              subject: my_module,
              message_items: message_items)
    end

    def valid?
      unless @my_module && @repository && @user && @params
        @errors[:invalid_arguments] =
          { 'my_module': @my_module,
            'repository': @repository,
            'params': @params,
            'user': @user }
          .map do |key, value|
            I18n.t('repositories.my_module_assigning_service.invalid_arguments', key: key.capitalize) if value.nil?
          end.compact
        return false
      end
      true
    end
  end
end
