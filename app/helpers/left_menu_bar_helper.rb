# frozen_string_literal: true

module LeftMenuBarHelper
  def left_menu_elements
    [
      {
        url: dashboard_path,
        name: t('left_menu_bar.dashboard'),
        icon: 'fa-thumbtack',
        active: dashboard_are_selected?,
        submenu: []
      }, {
        url: projects_path,
        name: t('left_menu_bar.projects'),
        icon: 'fa-folder',
        active: projects_are_selected?,
        submenu: []
      }, {
        url: repositories_path,
        name: t('left_menu_bar.repositories'),
        icon: 'fa-list-alt',
        active: repositories_are_selected?,
        submenu: []
      }, {
        url: "#",
        name: t('left_menu_bar.templates'),
        icon: 'fa-edit',
        active: protocols_are_selected? || label_templates_are_selected?,
        submenu: [{
          url: protocols_path,
          name: t('left_menu_bar.protocol'),
          active: protocols_are_selected?
        }, {
          url: label_templates_path,
          name: t('left_menu_bar.label'),
          active: label_templates_are_selected?
        }]
      }, {
        url: reports_path,
        name: t('left_menu_bar.reports'),
        icon: 'fa-clipboard-check',
        active: reports_are_selected?,
        submenu: []
      }, {
        url: global_activities_path,
        name: t('left_menu_bar.activities'),
        icon: 'fa-list',
        active: activities_are_selected?,
        submenu: []
      }
    ]
  end

  def dashboard_are_selected?
    controller_name == 'dashboards'
  end

  def projects_are_selected?
    controller_name.in? %w(projects experiments my_modules)
  end

  def repositories_are_selected?
    controller_name == 'repositories'
  end

  def protocols_are_selected?
    controller_name == 'protocols'
  end

  def label_templates_are_selected?
    controller_name == 'label_templates'
  end

  def reports_are_selected?
    # TODO
    controller_name == 'reports'
  end

  def settings_are_selected?
    controller_name.in? %(registrations preferences addons teams connected_accounts webhooks)
  end

  def activities_are_selected?
    controller_name == 'global_activities'
  end
end
