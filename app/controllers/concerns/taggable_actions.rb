# frozen_string_literal: true

module TaggableActions
  extend ActiveSupport::Concern

  included do
    before_action :load_taggable_item, only: %i(tag_resource untag_resource)
    before_action :load_tag, only: %i(tag_resource untag_resource)
    before_action :check_tag_manage_permissions, only: %i(tag_resource untag_resource)
  end

  def tag_resource
    tagging = @taggable_item.taggings.new(tag: @tag, created_by: current_user)
    if tagging.save
      render json: { tag: [@tag.id, @tag.name, @tag.color] }
    else
      render json: { status: :error }, status: :unprocessable_entity
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
end
