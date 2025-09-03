# frozen_string_literal: true

module Users
  module Settings
    class TagsController < ApplicationController
      before_action :load_team
      before_action :check_team_permissions
      before_action :load_vars, only: %i(update destroy merge)
      before_action :set_breadcrumbs_items, only: %i(index)

      def index
        respond_to do |format|
          format.html do
            @active_tab = :tags
          end
          format.json do
            tags = Lists::TagsService.new(@team.tags, params).call
            render json: tags, each_serializer: Lists::TagSerializer, user: current_user, meta: pagination_dict(tags)
          end
        end
      end

      def list
        @tags = @team.tags.order(:name)
      end

      def actions_toolbar
        render json: {
          actions:
            Toolbars::TagsService.new(
              current_user,
              @team,
              tag_ids: JSON.parse(params[:items]).pluck('id')
            ).actions
        }
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
          tags_to_merge = @team.tags.where(id: params[:merge_ids]).where.not(id: @tag.id)

          taggings_to_update = Tagging.where(tag_id: tags_to_merge.select(:id))
                                      .where.not(
                                        Tagging.where(tag_id: @tag.id).map{|i|
                                          Arel.sql("(taggable_type = '#{i.taggable_type}' AND taggable_id = #{i.taggable_id})")
                                        }.join(" OR ")
                                      )

          taggings_to_update.update!(tag_id: @tag.id)
          tags_to_merge.each(&:destroy!)

          render json: { message: :ok }, status: :ok
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
          raise ActiveRecord::Rollback
        end
      end

      private

      def load_team
        @team = current_user.teams.find_by(id: params[:team_id])
        render_404 unless @team
      end

      def check_team_permissions
        render_403 unless can_read_team?(@team)
      end

      def load_vars
        @tag = @team.tags.find_by(id: params[:id])

        render_404 unless @tag
      end

      def tag_params
        params.require(:tag).permit(:name, :color)
      end

      def set_breadcrumbs_items
        @breadcrumbs_items = [
          { label: t('breadcrumbs.teams'), url: teams_path },
          { label: @team.name, url: team_path(@team) }
        ]
      end
    end
  end
end
