# frozen_string_literal: true

module Users
  module Settings
    class WebhooksController < ApplicationController
      layout 'fluid'

      before_action :can_manage_filters
      before_action :load_filter, only: %i(destroy_filter filter_info)
      before_action :set_sort, only: %i(destroy_filter index)

      def index
        @activity_filters = ActivityFilter.order(name: (@current_sort == 'atoz' ? :asc : :desc))
      end

      def destroy_filter
        @filter.destroy
        redirect_to users_settings_webhooks_path(sort: @current_sort)
      end

      def filter_info
        render json: { filter_elements: load_filter_elements(@filter) }
      end

      private

      def can_manage_filters
        render_403 && return unless can_create_acitivity_filters?
      end

      def set_sort
        @current_sort = params[:sort] || 'atoz'
      end

      def load_filter
        @filter = ActivityFilter.find_by(id: params[:filter_id])

        render_404 && return unless @filter
      end

      def load_filter_elements(filter)
        result = []
        filters = filter.filter
        result += Team.where(id: filters['teams']).pluck(:name) if filters['teams']
        result += User.where(id: filters['users']).pluck(:full_name) if filters['users']

        if filters['types']
          result += Activity.type_ofs.select { |_k, v| filters['types'].include?(v.to_s) }
                            .map { |k, _v| I18n.t("global_activities.activity_name.#{k}") }
        end

        if filters['to_date'] || filters['from_date']
          result.push("#{t('global_activities.index.period_label')} #{filters['from_date']} - #{filters['to_date']}")
        end

        filters['subjects']&.each do |subject, ids|
          result += subject.constantize.where(id: ids).pluck(:name)
        end

        result
      end
    end
  end
end
