class SamplesController < ApplicationController
  before_action :load_vars, only: [:edit, :update, :destroy]
  before_action :load_vars_nested, only: [:new, :create]

  before_action :check_edit_permissions, only: [:edit]
  before_action :check_destroy_permissions, only: [:destroy]

  def new
    respond_to do |format|
      format.html
      if can_create_samples(@organization)
      format.json {
        render json: {
          sample_groups: @organization.sample_groups.as_json(only: [:id, :name, :color]),
          sample_types: @organization.sample_types.as_json(only: [:id, :name])
        }
      }
      else
        format.json { render json: {}, status: :unauthorized }
      end
    end
  end

  def create
    sample = Sample.new(
      user: current_user,
      organization: @organization
    )
    sample.last_modified_by = current_user
    errors = {
      init_fields: [],
      custom_fields: []
    };

    respond_to do |format|
      if can_create_samples(@organization)
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
          params[:custom_fields].to_a.each do |id, val|
            scf = SampleCustomField.new(
              custom_field_id: id,
              sample_id: sample.id,
              value: val
            )

            if !scf.save
              errors[:custom_fields] << {
                "#{id}": scf.errors.messages
              }
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
                sample: sample.name,
                organization: @organization.name
              )
            },
            status: :ok
          end
        else
          format.json { render json: errors, status: :bad_request }
        end
      else
        format.json { render json: {}, status: :unauthorized }
      end
    end
  end

  def edit
    json = {
      sample: {
        name: @sample.name,
        sample_type: @sample.sample_type.nil? ? "" : @sample.sample_type.id,
        sample_group: @sample.sample_group.nil? ? "" : @sample.sample_group.id,
        custom_fields: {}
      },
      sample_groups: @organization.sample_groups.as_json(only: [:id, :name, :color]),
      sample_types: @organization.sample_types.as_json(only: [:id, :name])
    }

    # Add custom fields ids as key (easier lookup on js side)
    @sample.sample_custom_fields.each do |scf|
      json[:sample][:custom_fields][scf.custom_field_id] = {
        sample_custom_field_id: scf.id,
        value: scf.value
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
        if can_edit_sample(sample)
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
          params[:custom_fields].to_a.each do |id, val|
            # Check if client is lying (SCF shouldn't exist)
            scf = SampleCustomField.where("custom_field_id = ? AND sample_id = ?", id, sample.id).take

            if scf
              # Well, client was naughty, no XMAS for him this year, update
              # existing SCF instead of creating new one
              scf.value = val

              if !scf.save
                # This client needs some lessons
                errors[:custom_fields] << {
                  "#{id}": scf.errors.messages
                }
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
              end
            end
          end

          scf_to_delete = []
          # Update all existing custom values
          params[:sample_custom_fields].to_a.each do |id, val|
            scf = SampleCustomField.find_by_id(id)

            if scf
              # SCF exists, but value is empty, add scf to queue to be deleted
              # (if everything is correct)
              if val.empty?
                scf_to_delete << scf
              else
                # SCF exists, update away
                scf.value = val

                if !scf.save
                  errors[:sample_custom_fields] << {
                    "#{id}": scf.errors.messages
                  }
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
                  sample: sample.name,
                  organization: @organization.name
                )
              },
              status: :ok
            end
          else
            format.json { render json: errors, status: :bad_request }
          end
        else
          format.json { render json: {}, status: :unauthorized }
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
    @organization = @sample.organization

    unless @sample
      render_404
    end
  end

  def load_vars_nested
    @organization = Organization.find_by_id(params[:organization_id])

    unless @organization
      render_404
    end
  end

  def check_create_permissions
    unless can_create_samples(@organization)
      render_403
    end
  end

  def check_edit_permissions
    unless can_edit_sample(@sample)
      render_403
    end
  end

  def check_destroy_permissions
    unless can_delete_samples(@organization)
      render_403
    end
  end

  def sample_params
    params.require(:sample).permit(
      :name,
      :sample_type_id,
      :sample_group_id
    )
  end
end
