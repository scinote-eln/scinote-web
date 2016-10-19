class Extends
  MY_MODULE_TABS = [
    {
      id: 'scinote_protocols',
      url: 'protocols',
      display_name: 'nav2.modules.protocols',
      glyphicon: 'glyphicon-circle-arrow-right',
      can_view_permission: 'can_view_module_protocols',
      can_uncheck: proc do |mm|
        mm.protocols.count.zero? || mm.protocol.steps.count.zero?
      end,
      opts: { id: 'steps-nav-tab' }
    },
    {
      id: 'scinote_results',
      url: 'results',
      display_name: 'nav2.modules.results',
      glyphicon: 'glyphicon-th',
      can_view_permission: 'can_view_results_in_module',
      can_uncheck: proc { |mm| mm.results.count.zero? },
      opts: { id: 'results-nav-tab' }
    },
    {
      id: 'scinote_activities',
      url: 'activities',
      display_name: 'nav2.modules.activities',
      glyphicon: 'glyphicon-equalizer',
      can_view_permission: 'can_view_module_activities',
      can_uncheck: proc { |_| true },
      opts: { id: 'activities-nav-tab' }
    },
    {
      id: 'scinote_samples',
      url: 'samples',
      display_name: 'nav2.modules.samples',
      glyphicon: 'glyphicon-tint',
      can_view_permission: 'can_view_module_samples',
      can_uncheck: proc { |mm| mm.samples.count.zero? },
      opts: { id: 'module-samples-nav-tab' }
    }
  ]
end
