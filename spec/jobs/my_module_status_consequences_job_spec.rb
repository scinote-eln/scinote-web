# frozen_string_literal: true

require 'rails_helper'

describe MyModuleStatusConsequencesJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:flow) { create :my_module_status_flow }
  let!(:previous_status) { create :my_module_status, my_module_status_flow: flow }
  let!(:next_status) { create :my_module_status, my_module_status_flow: flow, previous_status: previous_status }

  before do
    MyModuleStatusFlow.ensure_default
    my_module.update_columns(status_changing: true)
  end

  it 'runs forward consequences and clears the changing flag' do
    described_class.perform_now(my_module, [MyModuleStatusConsequences::Completion.new], :forward)

    my_module.reload
    expect(my_module.state).to eq 'completed'
    expect(my_module.completed_on).to be_present
    expect(my_module.status_changing).to be false
    expect(my_module.last_transition_error).to be_blank
  end

  it 'runs backward consequences' do
    consequence = MyModuleStatusConsequences::Uncompletion.new
    my_module.update_columns(state: 'completed', completed_on: Time.current)

    described_class.perform_now(my_module, [consequence], :backward)

    expect(my_module.reload.state).to eq 'uncompleted'
  end

  it 'keeps a previous transition error when in error rollback state' do
    my_module.update_columns(last_transition_error: { 'type' => 'general', 'message' => 'old' })
    my_module.transition_error_rollback = true

    described_class.perform_now(my_module, [], :forward)

    expect(my_module.reload.last_transition_error).to eq('type' => 'general', 'message' => 'old')
    expect(my_module.status_changing).to be false
  end

  context 'when a consequence fails with a general error' do
    let(:failing) do
      Class.new(MyModuleStatusConsequence) do
        def forward(_my_module)
          raise StandardError, 'boom'
        end
      end.new
    end

    it 'rolls back to the previous status and stores the error' do
      my_module.update_columns(my_module_status_id: next_status.id, changing_from_my_module_status_id: previous_status.id)

      described_class.perform_now(my_module, [failing], :forward)

      my_module.reload
      expect(my_module.my_module_status).to eq previous_status
      expect(my_module.status_changing).to be false
      expect(my_module.last_transition_error).to include('type' => 'general', 'message' => 'boom')
    end
  end

  context 'when a consequence fails with a repository snapshot error' do
    let(:repository) { create :repository, team: team, created_by: user }
    let!(:snapshot) do
      create :repository_snapshot, original_repository: repository, my_module: my_module, status: :provisioning
    end
    let!(:other_provisioning) do
      create :repository_snapshot, original_repository: repository, my_module: my_module, status: :provisioning
    end
    let(:failing) do
      error = { type: :repository_snapshot, repository_snapshot_id: snapshot.id, message: 'snapshot failed' }
      Class.new(MyModuleStatusConsequence) do
        define_method(:forward) do |_my_module|
          raise MyModuleStatus::MyModuleStatusTransitionError, error
        end
      end.new
    end

    it 'marks the snapshot failed, removes provisioning snapshots and stores the error' do
      my_module.update_columns(my_module_status_id: next_status.id, changing_from_my_module_status_id: previous_status.id)

      described_class.perform_now(my_module, [failing], :forward)

      expect(snapshot.reload.status).to eq 'failed'
      expect(RepositorySnapshot.exists?(other_provisioning.id)).to be false
      my_module.reload
      expect(my_module.last_transition_error).to include('type' => 'repository_snapshot',
                                                         'message' => 'snapshot failed')
      expect(my_module.my_module_status).to eq previous_status
    end
  end
end
