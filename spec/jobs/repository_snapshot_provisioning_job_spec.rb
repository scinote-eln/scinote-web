# frozen_string_literal: true

require 'rails_helper'

describe RepositorySnapshotProvisioningJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:snapshot) do
    create :repository_snapshot, original_repository: repository, my_module: my_module, status: :provisioning
  end

  it 'provisions the snapshot and marks it ready' do
    described_class.perform_now(snapshot)

    expect(snapshot.reload.status).to eq 'ready'
  end

  it 'marks the snapshot failed when provisioning does not succeed' do
    result = instance_double(Repositories::SnapshotProvisioningService, succeed?: false)
    allow(Repositories::SnapshotProvisioningService).to receive(:call).with(repository_snapshot: snapshot)
                                                                      .and_return(result)

    described_class.perform_now(snapshot)

    expect(snapshot.reload.status).to eq 'failed'
  end
end
