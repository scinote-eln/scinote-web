# frozen_string_literal: true

module TaggableActions
  extend ActiveSupport::Concern

  included do
    before_action :load_taggable_item, only: %i(tag_resource untag_resource tag_resource_with_new_tag)
    before_action :load_tag, only: %i(tag_resource untag_resource)
    before_action :check_tag_manage_permissions, only: %i(tag_resource untag_resource tag_resource_with_new_tag)
    before_action :check_tag_create_permissions, only: %i(tag_resource_with_new_tag)
  end

  def tag_resource
    tagging = @taggable_item.taggings.new(tag: @tag, created_by: current_user)
    if tagging.save
      render json: { tag: [@tag.id, @tag.name, @tag.color] }
    else
      render json: { status: :error }, status: :unprocessable_entity
    end
  end

  def tag_resource_with_new_tag
    ActiveRecord::Base.transaction do
      params[:tag][:color] = Constants::TAG_COLORS.sample.to_s if params[:tag][:color].blank?

      @tag = current_team.tags.create!(tag_params.merge(created_by: current_user, last_modified_by: current_user))
      tagging = @taggable_item.taggings.new(tag: @tag, created_by: current_user)
      tagging.save!
      render json: { tag: [@tag.id, @tag.name, @tag.color] }
    rescue ActiveRecord::RecordInvalid => e
      render json: { status: :error, error: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def untag_resource
    tagging = @taggable_item.taggings.find_by(tag_id: @tag.id)
    if tagging&.destroy
      render json: { status: :ok }
    else
      render json: { status: :error }, status: :unprocessable_entity
    end
  end

  private

  def tag_params
    params.require(:tag).permit(:name, :color)
  end

  def load_taggable_item
    @taggable_item = controller_name.singularize.camelize.constantize.find(params[:id])
  end

  def load_tag
    @tag = current_team.tags.find_by(id: params[:tag_id])
    render_404 unless @tag
  end

  def check_tag_manage_permissions
    raise NotImplementedError
  end

  def check_tag_create_permissions
    true # TODO: implement
  end
end
