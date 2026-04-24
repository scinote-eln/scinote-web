# frozen_string_literal: true

module StepElements
  class FormResponsesController < BaseController
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :check_manage_step_permissions, only: %i(create move_targets)
    before_action :check_forms_enabled, except: %i(destroy)
    before_action :load_form, only: :create
    before_action :load_step, only: :create
    before_action :load_form_response, except: :create
    before_action :check_manage_permissions, except: %i(create archive restore destroy submit reset move_targets)
    before_action :check_archive_permissions, only: :archive
    before_action :check_restore_permissions, only: :restore
    before_action :check_delete_permissions, only: :destroy
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def create
      render_403 and return unless can_create_protocol_form_responses?(@step.protocol)

      ActiveRecord::Base.transaction do
        @form_response = FormResponse.create!(form: @form, created_by: current_user, parent: @step)
        create_in_step!(@step, @form_response)
        log_step_form_activity(:form_added, { form: @form.id })
      end

      render_step_orderable_element(@form_response)
    end

    def submit
      render_403 and return unless can_submit_form_response?(@form_response)

      @form_response.submit!(current_user)
      log_step_form_activity(:form_field_submitted, { form: @form_response.form.id })

      render_step_orderable_element(@form_response)
    end

    def reset
      render_403 and return unless can_reset_form_response?(@form_response)

      new_form_response = @form_response.reset!(current_user)
      log_step_form_activity(:form_field_reopened, { form: @form_response.form.id })

      render_step_orderable_element(new_form_response)
    end

    def move
      target = @protocol.steps.find_by(id: params[:target_id])

      ActiveRecord::Base.transaction do
        @form_response.step_orderable_element.update!(step: target, position: target.next_element_position)
        @form_response.update!(parent: target)
        @step.normalize_elements_position

        log_step_form_activity(:form_moved,
                               {
                                 form: @form_response.form.id,
                                 step_position_destination: target.position + 1,
                                 step_destination: target.id
                               })

        render_step_orderable_element(@form_response)
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        log_step_form_activity(:form_deleted, { form: @form_response.form.id })
        if @form_response.destroy
          render json: {}, status: :ok
        else
          render json: { errors: @form_response.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

    def archive
      ActiveRecord::Base.transaction do
        @form_response.archive!(current_user)
        log_step_activity(:form_archived, { form: @form_response.form.id })
      end

      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def restore
      ActiveRecord::Base.transaction do
        @form_response.restore!(current_user)
        log_step_restore_activity(:task_step_form_restored, { form: @form_response.form.id })
      end

      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    private

    def form_response_params
      params.permit(:form_id, :step_id)
    end

    def load_form
      @form = Form.find_by(id: form_response_params[:form_id])

      render_404 unless @form && can_read_form?(@form)
    end

    def load_step
      @step = Step.find_by(id: form_response_params[:step_id])

      render_404 unless @step
    end

    def load_form_response
      @form_response = FormResponse.find_by(id: params[:id])

      render_404 unless @form_response
    end

    def check_forms_enabled
      render_404 unless Form.forms_enabled?
    end

    def check_manage_permissions
      render_403 unless can_manage_step_form_response?(@form_response)
    end

    def check_archive_permissions
      render_403 unless can_archive_step_form_response?(@form_response)
    end

    def check_restore_permissions
      render_403 unless can_restore_step_form_response?(@form_response)
    end

    def check_delete_permissions
      render_403 unless can_delete_step_form_response?(@form_response)
    end

    def log_step_form_activity(element_type_of, message_items = {})
      message_items[:my_module] = @protocol.my_module.id if @protocol.in_module?

      Activities::CreateActivityService.call(
        activity_type: "#{@step.protocol.in_module? ? 'task_step_' : 'protocol_step_'}#{element_type_of}",
        owner: current_user,
        team:  @protocol.team,
        project: @protocol.in_module? ? @protocol.my_module.project : nil,
        subject: @protocol,
        message_items: {
          user: current_user.id,
          step: @step.id,
          step_position: {
            id: @step.id,
            value_for: 'position_plus_one'
          }
        }.merge(message_items)
      )
    end
  end
end
