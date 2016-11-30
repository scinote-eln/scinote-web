class SampleTypesController < ApplicationController
  before_action :load_vars_nested, only: [:create,
                                          :index,
                                          :edit,
                                          :update,
                                          :sample_type_element,
                                          :destroy,
                                          :destroy_confirmation]
  before_action :check_create_permissions, only: [:create,
                                                  :edit,
                                                  :update,
                                                  :destroy,
                                                  :destroy_confirmation]
  before_action :set_sample_type, only: [:edit,
                                         :update,
                                         :destroy,
                                         :sample_type_element,
                                         :destroy,
                                         :destroy_confirmation]

  def create
    @sample_type = SampleType.new(sample_type_params)
    @sample_type.organization = @organization
    @sample_type.created_by = current_user
    @sample_type.last_modified_by = current_user

    respond_to do |format|
      if @sample_type.save
        format.json do
          render json: {
            id: @sample_type.id,
            name: @sample_type.name,
            edit: edit_organization_sample_type_path(current_organization,
                                                     @sample_type),
            destroy: organization_sample_type_path(current_organization,
                                                   @sample_type)
          },
          status: :ok
        end
      else
        format.json do
          render json: @sample_type.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def index
    render_404 unless current_organization
    @sample_types = current_organization.sample_types
  end

  def edit
    respond_to do |format|
      format.json do
        render json: {
          html:
            render_to_string(
              partial: 'edit.html.erb',
                       locals: { sample_type: @sample_type,
                                 organization: @organization }
            ),
          id: @sample_type.id
        }
      end
    end
  end

  def update
    @sample_type.update_attributes(sample_type_params)

    if @sample_type.save
      respond_to do |format|
        format.json do
          render json: {
            html: render_to_string(
              partial: 'sample_type.html.erb',
                       locals: { sample_type: @sample_type,
                                 organization: @organization }
            )
          }
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: @sample_type.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def destroy_confirmation
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'delete_sample_type_modal.html.erb',
                     locals: { sample_type: @sample_type,
                               organization: @organization }
          )
        }
      end
    end
  end

  def destroy
    flash[:success] = t 'sample_types.index.destroy_flash',
                        name: @sample_type.name
    Sample.where(sample_type: @sample_type).find_each do |sample|
      sample.update(sample_type_id: nil)
    end
    @sample_type.destroy
    redirect_to :back
  end

  def sample_type_element
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'sample_type.html.erb',
                     locals: { sample_type: @sample_type,
                               organization: @organization }
          )
        }
      end
    end
  end

  private

  def load_vars_nested
    @organization = Organization.find_by_id(params[:organization_id])

    unless @organization
      render_404
    end
  end

  def check_create_permissions
    unless can_create_sample_type_in_organization(@organization)
      render_403
    end
  end

  def set_sample_type
    @sample_type = SampleType.find_by_id(params[:id])
  end

  def sample_type_params
    params.require(:sample_type).permit(:name)
  end
end
