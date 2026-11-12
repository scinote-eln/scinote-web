# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::ActivitySerializer do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }

  def json_api_for(activity)
    ActiveModelSerializers::SerializableResource.new(activity, serializer: described_class).as_json
  end

  describe '.serializer_for' do
    it 'uses the task serializer for task subjects' do
      expect(described_class.serializer_for(my_module, {})).to eq Api::V1::TaskSerializer
    end

    it 'falls back to the default serializer of other subjects' do
      expect(described_class.serializer_for(project, {})).to eq ProjectSerializer
    end
  end

  context 'with an activity about a project' do
    let(:activity) do
      create :activity, type_of: :create_project, subject: project, owner: user, team: team, project: project,
                        values: { 'message_items' => { 'project' => { 'type' => 'Project', 'id' => project.id } } }
    end

    it 'exposes the id, the activity type and the timestamps' do
      attrs = described_class.new(activity).attributes

      expect(attrs).to include(id: activity.id, type_of: 'create_project',
                               created_at: activity.created_at, updated_at: activity.updated_at)
    end

    it 'generates the message from the activity type and its message items' do
      expect(described_class.new(activity).attributes[:message]).to eq(
        "<p>#{user.name} created project #{project.name}.</p>"
      )
    end

    it 'renders the project and owner relationships in json api format' do
      data = json_api_for(activity)[:data]

      expect(data[:type]).to eq 'activities'
      expect(data[:relationships][:project][:data]).to eq(id: project.id.to_s, type: 'projects')
      expect(data[:relationships][:user][:data]).to eq(id: user.id.to_s, type: 'users')
    end
  end

  context 'with a legacy activity without a subject' do
    let(:activity) { create :activity, :old, owner: user, team: team, message: 'Legacy text' }

    it 'returns the stored message as it is' do
      expect(described_class.new(activity).attributes[:message]).to eq 'Legacy text'
    end
  end
end
