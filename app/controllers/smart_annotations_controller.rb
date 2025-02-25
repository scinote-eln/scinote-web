class SmartAnnotationsController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  def parse_string
    render json: {
      annotations: custom_auto_link(
        params[:string],
        simple_format: false,
        tags: %w(img),
        team: current_team
      )
    }
  end

  def redirect
    redirect_to redirect_path
  end

  def user
    user_team_assignment = resource.user_assignments.find_by(assignable: current_team)

    render json: {
      full_name: resource.full_name,
      email: resource.email,
      avatar_url: user_avatar_absolute_url(resource, :thumb),
      info: I18n.t(
        'atwho.users.popover_html',
        role: user_team_assignment.user_role.name.capitalize,
        team: user_team_assignment.assignable.name,
        time: I18n.l(user_team_assignment.created_at, format: :full_date)
      )
    }
  end

  private

  def resource
    return @resource_class ||= User.find(params[:tag][1..].split('~')[1].base62_decode) if params[:tag][0] == '@'

    _, resource_tag, resource_id = params[:tag][1..].split('~')

    resource_id = resource_id.base62_decode

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
