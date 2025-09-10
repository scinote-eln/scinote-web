# frozen_string_literal: true

class TagsController < ApplicationController
  before_action :load_team, exccept: :index
  before_action :load_tag, only: %i(update destroy merge)
  before_action :check_create_permissions, only: %i(create merge)
  before_action :check_update_permissions, only: %i(update)
  before_action :check_delete_permissions, only: %i(destroy merge)

  def index
    @tags = if params[:teams].present?
              Tag.where(team: current_user.teams.where(id: params[:teams])).order(:name)
            else
              current_team.tags.order(:name)
            end
    @tags = @tags.where_attributes_like(['tags.name'], params[:query]) if params[:query].present?
  end

  def create
    @tag = @team.tags.new(tag_params)
    @tag.created_by = current_user
    @tag.last_modified_by = current_user

    if @tag.save
      #@log_activity(:create_tag, @tag.project, tag: @tag.id, project: @tag.project.id)
      render json: @tag, serializer: Lists::TagSerializer, user: current_user
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @tag.last_modified_by = current_user
    if @tag.update(tag_params)
      #log_activity(:edit_tag, @tag.project, tag: @tag.id, project: @tag.project.id)
      render json: @tag, serializer: Lists::TagSerializer, user: current_user
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    #log_activity(:delete_tag, @tag.project, tag: @tag.id, project: @tag.project.id)
    if @tag.destroy
      render json: { message: :ok }, status: :ok
    else
      render json: { error: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def merge
    ActiveRecord::Base.transaction do
      tags_to_remove = @team.tags.where(id: params[:merge_ids]).where.not(id: @tag.id)

      Tagging.where(tag_id: tags_to_remove.select(:id)).find_each do |tagging|
        if tagging.taggable.taggings.exists?(tag: @tag)
          tagging.destroy!
        else
          tagging.update!(tag_id: @tag.id)
        end
      end

      tags_to_remove.each(&:destroy!)

      render json: { message: :ok }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def colors
    render json: { colors: Constants::TAG_COLORS }
  end

  private

  def load_team
    @team = params[:team_id].present? ? current_user.teams.find_by(id: params[:team_id]) : current_team
    render_404 unless @team
  end

  def load_tag
    @tag = current_team.tags.find_by(id: params[:id])
    render_404 unless @tag
  end

  def check_create_permissions
    render_403 unless can_create_tags?(@team)
  end

  def check_update_permissions
    render_403 unless can_update_tags?(@team)
  end

  def check_delete_permissions
    render_403 unless can_delete_tags?(@team)
  end

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end
