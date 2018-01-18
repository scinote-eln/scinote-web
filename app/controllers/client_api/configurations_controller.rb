module ClientApi
  class ConfigurationsController < ApplicationController

    def about_scinote
      respond_to do |format|
        format.json do
          render json: {
            scinoteVersion: Scinote::Application::VERSION,
            addons: list_all_addons
          }, status: :ok
        end
      end
    end

    private

    def list_all_addons
      Rails::Engine.subclasses
                   .select { |c| c.name.start_with?('Scinote') }
                   .map { |c| c.parent.to_s }
    end
  end
end
