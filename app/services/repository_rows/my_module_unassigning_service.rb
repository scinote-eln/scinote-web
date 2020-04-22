# frozen_string_literal: true

module RepositoryRows
  class MyModuleUnassigningService
    extend Service

    attr_reader :repository, :my_module, :user, :params, :unassigned_rows_names, :errors

    def initialize(my_module:, repository:, user:, params:)
      @my_module = my_module
      @repository = repository
      @user = user
      @params = params
      @unassigned_rows_names = Set[]
      @errors = {}
    end

    def call
      return self unless valid?

      #ActiveRecord::Base.transaction do
        if params[:downstream] == 'true'
          @my_module.downstream_modules.each do |downstream_module|
            unassign_repository_rows_from_my_module(downstream_module)
          end
        else
          unassign_repository_rows_from_my_module(@my_module)
        end
      #rescue StandardError => e
      #  @errors[e.record.class.name.underscore] = e.record.errors.full_messages
      #  raise ActiveRecord::Rollback
      #end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    # Returns array of unassigned repository rows
    def unassign_repository_rows_from_my_module(my_module)
      unassigned_names = my_module.my_module_repository_rows
                                  .joins(:repository_row)
                                  .where(repository_row_id: params[:rows_to_unassign])
                                  .where(repository_rows: { repository: @repository })
                                  .select('my_module_id,
                                           my_module_repository_rows.id,
                                           repository_rows.name AS name')
                                  .destroy_all
                                  .pluck(:name)

      return [] if unassigned_names.blank?

      # update row last_modified_by
      my_module.repository_rows
               .where(repository: @repository, id: params[:rows_to_unassign])
               .update_all(last_modified_by_id: @user.id)

      Activities::CreateActivityService.call(activity_type: :unassign_repository_record,
                                             owner: @user,
                                             team: my_module.experiment.project.team,
                                             project: my_module.experiment.project,
                                             subject: my_module,
                                             message_items: { my_module: my_module.id,
                                                              repository: @repository.id,
                                                              record_names: unassigned_names.join(', ') })

      @unassigned_rows_names.merge(unassigned_names)
    end

    def valid?
      unless @my_module && @repository && @user && @params
        @errors[:invalid_arguments] =
          { 'my_module': @my_module,
            'repository': @repository,
            'params': @params,
            'user': @user }
          .map do |key, value|
            I18n.t('repositories.my_module_unassigning_service.invalid_arguments', key: key.capitalize) if value.nil?
          end.compact
        return false
      end
      true
    end
  end
end
