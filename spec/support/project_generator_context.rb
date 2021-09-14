RSpec.shared_context 'project_generator' do |config|
  login_user

  let(:user) { subject.current_user }
  let(:role) { create (config[:role] || :owner_role) }
  let!(:team) { create :team, created_by: user }
  let(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:project) { create :project, team: team }
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, experiment: experiment }
  let(:protocol) { create :protocol, my_module: my_module, team: team, added_by: user }

  if config[:tag]
    let(:tag) { create :tag, project: project}
  end

  if config[:project_comment]
    let(:project_comment) { create :project_comment, project: project, user: user }
  end

  if config[:my_module_comment]
    let(:my_module_comment) { create :task_comment, my_module: my_module, user: user }
  end

  if config[:step]
    let(:step) { create :step, protocol: protocol, user: user}

    if config[:step_comment]
      let(:step_comment) { create :step_comment, step: step, user: user}
    end

    if config[:step_asset]
      let(:step_asset) { create :step_asset, step: step }
    end

    if config[:step_table]
      let(:step_table) { create :step_table, step: step }
    end

    if config[:step_checklist]
      let(:step_checklist) { create :step_checklist, step: step }
    end
  end

  [:result_asset, :result_text, :result_table].each do |result|
    if config[result]
      let(result) { create result, result: (create :result, my_module: my_module, user: user )}

      if config[:result_comment]
        let("#{result}_comment") { create :result_comment, result: public_send(result).result, user: user }
      end
    end
  end

  before do
    create_user_assignment(my_module, role, user) unless config[:skip_assignments]
  end
end
