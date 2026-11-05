// Every keyboard shortcut in SciNote, in one place so clashes are easy to spot.
// Syntax: see keyboard_shortcuts.js.
//
// Server-rendered shortcuts are set with data-shortcut in the views and listed here as comments:
//   alt+shift+1 … alt+shift+6  Task tabs: Steps, Results, Assigned items, Activity, Archive,
//                              Analytical reports (my_modules/_header_actions.html.erb)
//   alt+shift+s                Task status dropdown (my_modules/status_flow/_task_flow_button.html.erb)

export default {
  SEARCH: 'mod+k',
  TASK_NEW_STEP: 'alt+shift+n',
  TASK_INVENTORIES: 'alt+shift+r',
  TASK_TOGGLE_STEPS: 'alt+shift+e',
  TASK_PRINT: 'mod+p'
};
