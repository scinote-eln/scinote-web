# frozen_string_literal: true

module Api
  module V1
    class ResultsController < BaseController
      include TinyMceHelper

      before_action :load_vars
      before_action :load_result, only: %i(show)
      before_action :check_manage_permissions, only: %i(create)

      def index
        results = @task.results
                       .page(params.dig(:page, :number))
                       .per(params.dig(:page, :size))
        render jsonapi: results, each_serializer: ResultSerializer,
                                 include: %i(text table file)
      end

      def create
        create_text_result if result_text_params.present?
        throw ActionController::ParameterMissing unless @result
        render jsonapi: @result,
               serializer: ResultSerializer,
               include: %i(text table file),
               status: :created
      end

      def show
        render jsonapi: @result, serializer: ResultSerializer,
                                 include: %i(text table file)
      end

      private

      def load_vars
        @team = Team.find(params.require(:team_id))
        unless can_read_team?(@team)
          return render jsonapi: {}, status: :forbidden
        end
        @project = @team.projects.find(params.require(:project_id))
        unless can_read_project?(@project)
          return render jsonapi: {}, status: :forbidden
        end
        @experiment = @project.experiments.find(params.require(:experiment_id))
        unless can_read_experiment?(@experiment)
          return render jsonapi: {}, status: :forbidden
        end
        @task = @experiment.my_modules.find(params.require(:task_id))
      end

      def load_result
        @result = @task.results.find(params.require(:id))
      end

      def check_manage_permissions
        render body: nil, status: :forbidden unless can_manage_module?(@task)
      end

      def create_text_result
        result_text = ResultText.new(text: result_text_params[:text])
        result_text.transaction do
          if tiny_mce_asset_params.present?
            tiny_mce_asset_params.each do |t|
              image_params = t[:attributes]
              token = image_params[:file_token]
              unless result_text.text["[~tiny_mce_id:#{token}]"]
                raise StandardError, 'Image reference not found in the text'
              end
              image = Paperclip.io_adapters.for(image_params[:file_data])
              image.original_filename = image_params[:file_name]
              tiny_img = TinyMceAsset.create!(image: image, team: @team)
              result_text.text.sub!("[~tiny_mce_id:#{token}]",
                                    "[~tiny_mce_id:#{tiny_img.id}]")
            end
          end
          @result = Result.new(
            user: current_user,
            my_module: @task,
            name: result_params[:name],
            result_text: result_text,
            last_modified_by: current_user
          )
          @result.save! && result_text.save!
          link_tiny_mce_assets(result_text.text, result_text)
        end
      end

      def result_params
        unless params.require(:data).require(:type) == 'results'
          raise ActionController::BadRequest,
                'Wrong object type within parameters'
        end
        params.require(:data).require(:attributes).require(:name)
        params.permit(data: { attributes: :name })[:data][:attributes]
      end

      # Partially implement sideposting draft
      # https://github.com/json-api/json-api/pull/1197
      def result_text_params
        prms =
          params[:included]&.select { |el| el[:type] == 'result_texts' }&.first
        prms.require(:attributes).require(:text)
        prms[:attributes]
      end

      def tiny_mce_asset_params
        prms = params[:included]&.select { |el| el[:type] == 'tiny_mce_assets' }
        prms.each do |p|
          p.require(:attributes).require(%i(file_data file_name file_token))
        end
        file_tokens = prms.map { |p| p[:attributes][:file_token] }
        result_text_params[:text].scan(
          /\[~tiny_mce_id:(\w+)\]/
        ).flatten.each do |token|
          unless file_tokens.include?(token)
            raise StandardError,
                  'Text contains reference to nonexisting TinyMCE image'
          end
        end
        prms
      end
    end
  end
end
