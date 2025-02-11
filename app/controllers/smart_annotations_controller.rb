# frozen_string_literal: true

class SmartAnnotationsController < ApplicationController
  def redirect
    redirect_to redirect_path
  end

  private

  def resource
    prefix = params[:tag].first

    return unless prefix == '#'

    _, resource_tag, resource_id = params[:tag][1..].split('~')

    resource_class =
      case resource_tag
      when 'prj'
        Project
      when 'exp'
        Experiment
      when 'tsk'
        MyModule
      when 'rep_item'
        RepositoryRow
      end

    @resource ||= resource_class.find(resource_id)
  end

  def redirect_path
    case resource
    when Project
      project_path(resource)
    when Experiment
      my_modules_experiment_path(resource)
    when MyModule
      protocols_my_module_path(resource)
    when RepositoryRow
      repository_repository_row_path(resource.repository, resource)
    end
  end
end
