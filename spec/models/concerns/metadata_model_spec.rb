# frozen_string_literal: true

require 'rails_helper'

describe MetadataModel, type: :concern do
  let!(:user) { create :user }
  let!(:team) { create :team, created_by: user }

  let!(:project_1) do
    Project.create!(
      name: 'Project 1',
      team: user.teams.first,
      created_by: user,
      metadata: {
        status: 'processed',
        info: {
          tag: 'important',
          number: 2
        }
      }
    )
  end

  let!(:project_2) do
    Project.create!(
      name: 'Project 2',
      team: user.teams.first,
      created_by: user,
      metadata: {
        status: 'failed'
      }
    )
  end

  let!(:experiment_1) do
    Experiment.create!(
      name: Faker::Name.unique.name,
      project: project_1,
      created_by: user,
      last_modified_by: user,
      metadata: {
        status: 'processed',
        info: {
          tag: 'important',
          number: 2
        }
      }
    )
  end

  let!(:experiment_2) do
    Experiment.create!(
      name: Faker::Name.unique.name,
      project: project_2,
      created_by: user,
      last_modified_by: user,
      metadata: {
        status: 'failed'
      }
    )
  end

  it '#with_metadata_value finds the correct project by metadata value' do
    results = Project.with_metadata_value(:status, 'processed')
    expect(results.count).to eq 1
    expect(results.last.id).to eq project_1.id
  end

  it '#with_metadata_value finds the correct project by nested metadata value' do
    results = Project.with_metadata_value('info.tag', 'important')
    expect(results.count).to eq 1
    expect(results.last.id).to eq project_1.id

    results = Project.with_metadata_value('info.number', 2)
    expect(results.count).to eq 1
    expect(results.last.id).to eq project_1.id
  end

  it '#with_metadata_value escapes key input' do
    results = nil
    expect { results = Project.with_metadata_value("project'->>'tag' = \'one\') AND name", nil) }.to_not raise_error
    expect(results.count).to eq 0
  end

  it '#with_metadata_value finds the correct experiment by metadata value' do
    results = Experiment.with_metadata_value(:status, 'processed')
    expect(results.count).to eq 1
    expect(results.last.id).to eq experiment_1.id
  end

  it '#with_metadata_value finds the correct experiment by nested metadata value' do
    results = Experiment.with_metadata_value('info.tag', 'important')
    expect(results.count).to eq 1
    expect(results.last.id).to eq experiment_1.id

    results = Experiment.with_metadata_value('info.number', 2)
    expect(results.count).to eq 1
    expect(results.last.id).to eq experiment_1.id
  end

  it '#with_metadata_value experiment escapes key input' do
    results = nil
    expect { results = Experiment.with_metadata_value("experiment'->>'tag' = \'one\') AND name", nil) }.to_not raise_error
    expect(results.count).to eq 0
  end
end
