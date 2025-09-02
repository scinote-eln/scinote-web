# frozen_string_literal: true

module TaggableActions
  extend ActiveSupport::Concern

  included do
    before_action :load_taggable_item, only: %i(link_tag unlink_tag)
    before_action :load_tag, only: %i(link_tag unlink_tag)
  end

  def link_tag
    tagging = @taggable_item.taggings.new(tag: @tag, created_by: current_user)
    if tagging.save
      render json: { tag: [@tag.id, @tag.name, @tag.color] }
    else
      render json: { status: :error }, status: :unprocessable_entity
    end
  end

  def unlink_tag
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
    @tag = @taggable_item.team.tags.find_by(id: params[:tag_id])
    render_404 unless @tag
  end
end
