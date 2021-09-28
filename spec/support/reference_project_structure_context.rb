#  Example
#
#  include_context 'reference_project_structure', {
#    role: :owner,
#    result_asset: true,
#    step: true,
#    team: @team,
#    step_asset: true,
#    result_comment: true,
#    project_comments: 4,
#    tags: 2,
#    skip_assignments: true
#  }

RSpec.shared_context 'reference_project_structure' do |config|
  config ||= {}
  let!(:user) { subject.current_user }
  let!(:role) do
    if config[:role]
      UserRole.find_by(name: I18n.t("user_roles.predefined.#{config[:role]}")) || create("#{config[:role]}_role")
    else
      UserRole.find_by(name: I18n.t("user_roles.predefined.owner")) || UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
    end
  end
  let!(:team) { config[:team] || (create :team, created_by: user) }
  let!(:user_team) { create :user_team, config[:team_role] || :admin, user: user, team: team }

  let!(:project) { role && create(:project, team: team, created_by: user) }
  let!(:projects) { role && create_list(:project, config[:projects], team: team, created_by: user) } if config[:projects]

  let!(:experiment) { create :experiment, project: project } unless config[:skip_experiment]
  let!(:experiments) { create_list :experiment, config[:experiments], project: project } if config[:experiments]

  let!(:my_module) { create :my_module, experiment: experiment, created_by: user } unless config[:skip_my_module]
  let!(:my_modules) { create_list :my_module, config[:my_modules], experiment: experiment } if config[:my_modules]

  let(:tag) { create :tag, project: project} if config[:tag]
  let(:tags) { create_list :tag, config[:tags], project: project} if config[:tags]

  let(:project_comment) { create :project_comment, project: project, user: user } if config[:project_comment]
  let(:project_comments) { create_list :project_comment, config[:project_comments], project: project, user: user } if config[:project_comments]

  let(:my_module_comment) { create :task_comment, my_module: my_module, user: user } if config[:my_module_comment]
  let(:my_module_comments) { create_list :task_comment, config[:my_module_comments], my_module: my_module, user: user } if config[:my_module_comments]

  if config[:step]
    let(:step) { create :step, protocol: my_module.protocol, user: user}
    let(:step_comment) { create :step_comment, step: step, user: user} if config[:step_comment]
    let(:step_comments) { create_list :step_comment, config[:step_comments], step: step, user: user} if config[:step_comments]

    [:step_asset, :step_table, :step_checklist].each do |step_component|
      let(step_component) { create step_component, step: step } if config[step_component]
    end
    [:step_assets, :step_tables, :step_checklists].each do |step_components|
      let(step_components) { create_list step_components, config[step_components], step: step } if config[step_components]
    end
  end

  if config[:steps]
    let(:steps) { create_list :step, config[:steps], protocol: my_module.protocol, user: user}
  end

  [:result_asset, :result_text, :result_table].each do |result|
    if config[result]
      let(result) { create result, result: (create :result, my_module: my_module, user: user )}
      let("#{result}_comment") { create :result_comment, result: public_send(result).result, user: user } if config[:result_comment]
      let("#{result}_comments") { create_list :result_comment, config[:result_comments], result: public_send(result).result, user: user } if config[:result_comments]
    end
  end

  [:result_assets, :result_texts, :result_tables].each do |result|
    if config[result]
      let(result) { create_list result, config[result], result: (create :result, my_module: my_module, user: user )}
    end
  end

  before do
    unless config[:skip_assignments]
      if config[:skip_my_module]
        create_user_assignment(experiment, role, user)
      else
        create_user_assignment(my_module, role, user)
      end
    end
  end
end
