# frozen_string_literal: true

module LeftMenuBarHelper
  def left_menu_elements
    [
      {
        url: dashboard_path,
        name: t('left_menu_bar.dashboard'),
        icon: 'sn-icon-dashboard',
        active: dashboard_are_selected?,
        submenu: []
      }, {
        url: projects_path,
        name: t('left_menu_bar.projects'),
        icon: 'sn-icon-projects',
        active: projects_are_selected?,
        submenu: []
      }, {
        url: repositories_path,
        name: t('left_menu_bar.repositories'),
        icon: 'sn-icon-inventory',
        active: repositories_are_selected? || storage_locations_are_selected?,
        submenu: [{
          url: repositories_path,
          name: t('left_menu_bar.items'),
          active: repositories_are_selected?
        }, {
          url: storage_locations_path,
          name: t('left_menu_bar.locations'),
          active: storage_locations_are_selected?
        }]
      }, {
        url: "#",
        name: t('left_menu_bar.templates'),
        icon: 'sn-icon-protocols-templates',
        active: protocols_are_selected? || label_templates_are_selected? || forms_are_selected?,
        submenu: template_submenu
      }, {
        url: reports_path,
        name: t('left_menu_bar.reports'),
        icon: 'sn-icon-reports',
        active: reports_are_selected?,
        submenu: []
      }, {
        url: global_activities_path,
        name: t('left_menu_bar.activities'),
        icon: 'sn-icon-activities',
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

  def storage_locations_are_selected?
    controller_name == 'storage_locations'
  end

  def protocols_are_selected?
    controller_name == 'protocols'
  end

  def forms_are_selected?
    controller_name == 'forms'
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

  def template_submenu
    submenu = [
      {
        url: protocols_path,
        name: t('left_menu_bar.protocol'),
        active: protocols_are_selected?
      }, {
        url: label_templates_path,
        name: t('left_menu_bar.label'),
        active: label_templates_are_selected?
      }
    ]

    if Form.forms_enabled?
      submenu.unshift({
                        url: forms_path,
                        name: t('left_menu_bar.forms'),
                        active: forms_are_selected?
                      })
    end
    submenu
  end
end
