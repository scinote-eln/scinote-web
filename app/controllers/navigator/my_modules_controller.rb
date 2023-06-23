# frozen_string_literal: true

module Navigator
  class MyModulesController < BaseController
    before_action :load_my_module
    before_action :check_read_permissions

    def tree
      my_modules = my_module_level_branch(@experiment)
      experiments = experiment_level_branch(@experiment)
      experiments.find { |i| i[:id] == @experiment.code }[:children] = my_modules

      tree = project_level_branch(@experiment.project)
      tree.find { |i| i[:id] == @experiment.project.code }[:children] = experiments

      tree = build_folder_tree(@experiment.project.project_folder, tree) if @experiment.project.project_folder

      render json: { items: tree }
    end

    private

    def load_my_module
      @my_module = MyModule.find_by(id: params[:id])

      @experiment = @my_module.experiment
    end

    def check_read_permissions
      render_403 and return unless can_read_my_module?(@my_module)
    end
  end
end
