# frozen_string_literal: true

require 'rails_helper'

describe Activities::CreateActivityService do
  let(:user) { create :user }
  let(:team) { create :team, :with_members }
  let(:project) do
    create :project, team: team, user_projects: []
  end
  let(:service_call) do
    Activities::CreateActivityService
      .call(activity_type: :create_project,
            owner: user,
            subject: project,
            team: team,
            project: project,
            message_items: { project: project.id })
  end

  it 'adds new activiy in DB' do
    expect { service_call }.to(change { Activity.count })
  end
end
