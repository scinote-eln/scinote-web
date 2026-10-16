# frozen_string_literal: true

require 'rails_helper'

describe MyModules::CopyContentJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:source) { create :my_module, experiment: experiment, created_by: user }
  let(:target) { create :my_module, experiment: experiment, created_by: user }

  it 'copies content, logs the clone activity and marks the target as done' do
    allow(Activities::CreateActivityService).to receive(:call)

    described_class.perform_now(user.id, source.id, target.id)

    expect(target.reload.provisioning_status).to eq 'done'
    expect(Activities::CreateActivityService).to have_received(:call).with(
      hash_including(activity_type: :clone_module, subject: target, owner: user)
    )
  end

  it 'skips the activity when skip_activities is set' do
    expect(Activities::CreateActivityService).not_to receive(:call)

    described_class.perform_now(user.id, source.id, target.id, skip_activities: true)

    expect(target.reload.provisioning_status).to eq 'done'
  end

  it 'marks the target as failed when copying raises' do
    allow_any_instance_of(MyModule).to receive(:copy_content).and_raise(StandardError, 'copy failed')

    described_class.perform_now(user.id, source.id, target.id)

    expect(target.reload.provisioning_status).to eq 'failed'
  end
end
