# frozen_string_literal: true

class SmartAnnotationsController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  def show
    if params[:data]
      render json: {
        name: resource_readable? && resource.name,
        type: resource_tag
      }
    else
      redirect_to redirect_path
    end
  end

  def user
    user_team_assignment = resource.user_assignments.find_by(assignable: current_team)
    render json: {
      name: resource.name,
      email: resource.email,
      avatar_url: user_avatar_absolute_url(resource, :thumb),
      info: I18n.t(
        'atwho.users.popover_html',
        role: user_team_assignment ? user_team_assignment.user_role.name.capitalize : '/',
        team: user_team_assignment ? user_team_assignment.assignable.name : I18n.t('atwho.users.not_in_this_team'),
        time: user_team_assignment ? I18n.l(user_team_assignment.created_at, format: :full_date) : '/'
      )
    }
  end

  private

  def sa_tag
    @sa_tag ||= params[:tag][1..].split('~')[1]
  end

  def resource_tag
    @resource_tag ||= resource.is_a?(RepositoryRow) ? repository_acronym(resource.repository) : sa_tag
  end

  def resource
    return @resource_class ||= User.find(sa_tag.base62_decode) if params[:tag][0] == '@'

    resource_id = params[:tag][1..].split('~').last

    resource_id = resource_id.base62_decode

    resource_class =
      case sa_tag
      when 'prj'
        Project
      when 'exp'
        Experiment
      when 'tsk'
        MyModule
      when 'rep_item'
        RepositoryRow
      end

    @resource ||= resource_class.find_by(id: resource_id)
  end

  def resource_readable?
    return false unless resource

    @resource_readable ||=
      case resource
      when RepositoryRow
        resource.repository.readable_by_user?(current_user)
      else
        resource.readable_by_user?(current_user)
      end
  end

  def redirect_path
    case resource
    when Project
      experiments_path(project_id: resource.id)
    when Experiment
      my_modules_experiment_path(resource)
    when MyModule
      protocols_my_module_path(resource)
    when RepositoryRow
      repository_repository_row_path(resource.repository, resource, my_module_id: params[:my_module_id])
    end
  end

  def repository_acronym(repository)
    words = repository.name.strip.split
    case words.size
    when 1 then words[0][0..2]
    when 2 then words[0][0..1] + words[1][0]
    else words[0..2].map(&:chr).join
    end.capitalize
  end
end
