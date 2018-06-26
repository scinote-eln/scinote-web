class SamplesController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  before_action :load_vars, only: [:edit, :update, :destroy, :show]
  before_action :load_vars_nested, only: [:new, :create]

  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(edit update destroy)

  def new
    respond_to do |format|
      format.html
      groups = @team.sample_groups.map do |g|
        { id: g.id, name: sanitize_input(g.name), color: g.color }
      end
      types = @team.sample_types.map do |t|
        { id: t.id, name: sanitize_input(t.name) }
      end
      format.json do
        render json: {
          sample_groups: groups.as_json,
          sample_types: types.as_json
        }
      end
    end
  end

  def create
    sample = Sample.new(
      user: current_user,
      team: @team
    )
    sample.last_modified_by = current_user
    errors = {
      init_fields: [],
      custom_fields: []
    };

    respond_to do |format|
      if params[:sample]
        # Sample name
        if params[:sample][:name]
          sample.name = params[:sample][:name]
        end

        # Sample type
        if params[:sample][:sample_type_id] != "-1"
          sample_type = SampleType.find_by_id(params[:sample][:sample_type_id])

          if sample_type
            sample.sample_type_id = params[:sample][:sample_type_id]
          end
        end

        # Sample group
        if params[:sample][:sample_group_id] != "-1"
          sample_group = SampleGroup.find_by_id(params[:sample][:sample_group_id])

          if sample_group
            sample.sample_group_id = params[:sample][:sample_group_id]
          end
        end
      end

      if !sample.save
        errors[:init_fields] = sample.errors.messages
      else
        # Sample was saved, we can add all newly added sample fields
        custom_fields_params.to_a.each do |id, val|
          scf = SampleCustomField.new(
            custom_field_id: id,
            sample_id: sample.id,
            value: val
          )

          if !scf.save
            errors[:custom_fields] << {
              "#{id}": scf.errors.messages
            }
          else
            sample_annotation_notification(sample, scf)
          end
        end
      end

      errors.delete_if { |k, v| v.blank? }
      if errors.empty?
        format.json do
          render json: {
            id: sample.id,
            flash: t(
              'samples.create.success_flash',
              sample: escape_input(sample.name),
              team: escape_input(@team.name)
            )
          },
          status: :ok
        end
      else
        format.json { render json: errors, status: :bad_request }
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'info_sample_modal.html.erb'
          )
        }
      end
    end
  end

  def edit
    json = {
      sample: {
        name: escape_input(@sample.name),
        sample_type: @sample.sample_type.nil? ? "" : @sample.sample_type.id,
        sample_group: @sample.sample_group.nil? ? "" : @sample.sample_group.id,
        custom_fields: {}
      },
      sample_groups: @team.sample_groups.map do |g|
        { id: g.id, name: sanitize_input(g.name), color: g.color }
      end,
      sample_types: @team.sample_types.map do |t|
        { id: t.id, name: sanitize_input(t.name) }
      end
    }

    # Add custom fields ids as key (easier lookup on js side)
    @sample.sample_custom_fields.each do |scf|
      json[:sample][:custom_fields][scf.custom_field_id] = {
        sample_custom_field_id: scf.id,
        value: escape_input(scf.value)
      }
    end

    respond_to do |format|
      format.html
      format.json {
        render json: json
      }
    end
  end

  def update
    sample = Sample.find_by_id(params[:sample_id])
    sample.last_modified_by = current_user
    errors = {
      init_fields: [],
      sample_custom_fields: [],
      custom_fields: []
    };

    respond_to do |format|
      if sample
        if params[:sample]
          if params[:sample][:name]
            sample.name = params[:sample][:name]
          end

          # Check if user selected empty sample type
          if params[:sample][:sample_type_id] == "-1"
            sample.sample_type_id = nil
          elsif params[:sample][:sample_type_id]
            sample_type = SampleType.find_by_id(params[:sample][:sample_type_id])

            if sample_type
              sample.sample_type_id = params[:sample][:sample_type_id]
            end
          end

          # Check if user selected empty sample type
          if params[:sample][:sample_group_id] == "-1"
            sample.sample_group_id = nil
          elsif params[:sample][:sample_group_id]
            sample_group = SampleGroup.find_by_id(params[:sample][:sample_group_id])

            if sample_group
              sample.sample_group_id = params[:sample][:sample_group_id]
            end
          end
        end

        # Add all newly added sample fields
        custom_fields_params.to_a.each do |id, val|
          # Check if client is lying (SCF shouldn't exist)
          scf = SampleCustomField.where("custom_field_id = ? AND sample_id = ?", id, sample.id).take

          if scf
            old_text = scf.value
            # Well, client was naughty, no XMAS for him this year, update
            # existing SCF instead of creating new one
            scf.value = val

            if !scf.save
              # This client needs some lessons
              errors[:custom_fields] << {
                "#{id}": scf.errors.messages
              }
            else
              sample_annotation_notification(sample, scf, old_text)
            end
          else
            # SCF doesn't exist, create it
            scf = SampleCustomField.new(
              custom_field_id: id,
              sample_id: sample.id,
              value: val
            )

            if !scf.save
              errors[:custom_fields] << {
                "#{id}": scf.errors.messages
              }
            else
              sample_annotation_notification(sample, scf)
            end
          end
        end

        scf_to_delete = []
        # Update all existing custom values
        sample_custom_fields_params.to_a.each do |id, val|
          scf = SampleCustomField.find_by_id(id)

          if scf
            # SCF exists, but value is empty, add scf to queue to be deleted
            # (if everything is correct)
            if val.empty?
              scf_to_delete << scf
            else
              old_text = scf.value
              # SCF exists, update away
              scf.value = val

              if !scf.save
                errors[:sample_custom_fields] << {
                  "#{id}": scf.errors.messages
                }
              else
                sample_annotation_notification(sample, scf, old_text)
              end
            end
          else
            # SCF doesn't exist, we can't do much but yield error
            errors[:sample_custom_fields] << {
              "#{id}": I18n.t("samples.edit.scf_does_not_exist")
            }
          end
        end

        if !sample.save
          errors[:init_fields] = sample.errors.messages
        end

        errors.delete_if { |k, v| v.blank? }
        if errors.empty?
          # Now we can destroy empty scfs
          scf_to_delete.map(&:destroy)

          format.json do
            render json: {
              id: sample.id,
              flash: t(
                'samples.update.success_flash',
                sample: escape_input(sample.name),
                team: escape_input(@team.name)
              )
            },
            status: :ok
          end
        else
          format.json { render json: errors, status: :bad_request }
        end
      else
        format.json { render json: {}, status: :not_found }
      end
    end
  end

  def destroy
  end

  private

  def load_vars
    @sample = Sample.find_by_id(params[:id])
    @team = current_team

    unless @sample
      render_404
    end
  end

  def load_vars_nested
    @team = Team.find_by_id(params[:team_id])

    unless @team
      render_404
    end
  end

  def check_create_permissions
    render_403 unless can_create_samples?(@team)
  end

  def check_manage_permissions
    render_403 unless can_manage_sample?(@sample)
  end

  def sample_params
    params.require(:sample).permit(
      :name,
      :sample_type_id,
      :sample_group_id
    )
  end

  def custom_fields_params
    params.permit(custom_fields: {}).to_h[:custom_fields]
  end

  def sample_custom_fields_params
    params.permit(sample_custom_fields: {}).to_h[:sample_custom_fields]
  end

  def sample_annotation_notification(sample, scf, old_text = nil)
    table_url = params.fetch(:request_url) { :request_url_must_be_present }
    smart_annotation_notification(
      old_text: (old_text if old_text),
      new_text: scf.value,
      title: t('notifications.sample_annotation_title',
               user: current_user.full_name,
               column: scf.custom_field.name,
               sample: sample.name),
      message: t('notifications.sample_annotation_message_html',
                 sample: link_to(sample.name, table_url),
                 column: link_to(scf.custom_field.name, table_url))
    )
  end
end
