# frozen_string_literal: true

module LeftMenuBarHelper
  def left_menu_elements
    menu = []

    menu.push({
                url: dashboard_path,
                name: t('left_menu_bar.dashboard'),
                icon: 'sn-icon-dashboard',
                active: dashboard_are_selected?
              })

    menu.push({
                url: projects_path,
                name: t('left_menu_bar.projects'),
                icon: 'sn-icon-projects',
                active: projects_are_selected?
              })

    menu.push({
                url: repositories_path,
                name: t('left_menu_bar.items'),
                icon: 'sn-icon-inventory',
                active: repositories_are_selected?
              })

    menu.push({
                url: storage_locations_path,
                name: t('left_menu_bar.locations'),
                icon: 'sn-icon-location',
                active: storage_locations_are_selected?
              })

    menu.push({
                url: forms_path,
                name: t('left_menu_bar.forms'),
                icon: 'sn-icon-forms',
                active: forms_are_selected?
              })

    menu.push({
                url: protocols_path,
                name: t('left_menu_bar.protocol'),
                icon: 'sn-icon-protocols-templates',
                active: protocols_are_selected?
              })

    menu.push({
                url: label_templates_path,
                name: t('left_menu_bar.label'),
                icon: 'sn-icon-printer-labels',
                active: label_templates_are_selected?
              })

    menu.push({
                url: reports_path,
                name: t('left_menu_bar.reports'),
                icon: 'sn-icon-reports',
                active: reports_are_selected?
              })

    menu.push({
                url: global_activities_path,
                name: t('left_menu_bar.activities'),
                icon: 'sn-icon-activities',
                active: activities_are_selected?
              })

    private_methods.select { |i| i.to_s[/^left_menu_[a-z]*_extension$/] }.each do |method|
      menu = __send__(method, menu)
    end

    menu
  end

  def dashboard_are_selected?
    controller_name == 'dashboards'
  end

  def projects_are_selected?
    controller_name.in? %w(projects experiments my_modules results)
  end

  def repositories_are_selected?
    controller_name == 'repositories'
  end

  def storage_locations_are_selected?
    controller_name == 'storage_locations'
  end

  def protocols_are_selected?
    controller_name.in? %w(protocols result_templates protocol_repository_rows)
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
end
