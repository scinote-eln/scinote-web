class CustomFieldsController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars, except: :create
  before_action :load_vars_nested, only: [:create, :destroy_html]
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, except: :create

  def create
    @custom_field = CustomField.new(custom_field_params)
    @custom_field.team = @team
    @custom_field.user = current_user

    respond_to do |format|
      if @custom_field.save
        format.json do
          render json: {
            id: @custom_field.id,
            name: escape_input(@custom_field.name),
            edit_url:
              edit_team_custom_field_path(@team, @custom_field),
            update_url:
              team_custom_field_path(@team, @custom_field),
            destroy_html_url:
              team_custom_field_destroy_html_path(
                @team, @custom_field
              )
          },
          status: :ok
        end
      else
        format.json do
          render json: @custom_field.errors.to_json,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.json do
        render json: { status: :ok }
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        @custom_field.update_attributes(custom_field_params)
        if @custom_field.save
          render json: { status: :ok }
        else
          render json: @custom_field.errors.to_json,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def destroy_html
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'samples/delete_custom_field_modal_body.html.erb',
            locals: { column_index: params[:column_index] }
          )
        }
      end
    end
  end

  def destroy
    @del_custom_field = @custom_field.dup
    respond_to do |format|
      format.json do
        if @custom_field.destroy
          SamplesTable.update_samples_table_state(
            @del_custom_field,
            params[:custom_field][:column_index]
          )
          render json: { status: :ok }
        else
          render json: { status: :unprocessable_entity }
        end
      end
    end
  end

  private

  def load_vars
    @custom_field = CustomField.find_by_id(params[:id])
    @custom_field = CustomField.find_by_id(
      params[:custom_field_id]
    ) unless @custom_field
    render_404 unless @custom_field
  end

  def load_vars_nested
    @team = Team.find_by_id(params[:team_id])
    render_404 unless @team
  end

  def check_create_permissions
    render_403 unless can_create_sample_columns?(@team)
  end

  def check_manage_permissions
    render_403 unless can_manage_sample_column?(@custom_field)
  end

  def custom_field_params
    params.require(:custom_field).permit(:name)
  end
end
