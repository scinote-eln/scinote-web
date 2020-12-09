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
            message_items: { project: project.id })
  end

  it 'adds new activiy in DB' do
    expect { service_call }.to(change { Activity.count })
  end

  context 'enrich message items with values and types' do
    before do
      allow_any_instance_of(Activity).to receive(:save!).and_return(true)
    end

    context 'when there is no message items' do
      it 'your message items remains empty' do
        activity = Activities::CreateActivityService
                   .call(activity_type: :create_project,
                           owner: user,
                           subject: project,
                           team: team).activity

        expect(activity.message_items).to be == {}
      end
    end

    context 'when message item is simple string' do
      it 'not transform message_item to hash' do
        custom_call =
          Activities::CreateActivityService
          .call(activity_type: :create_project,
                  owner: user,
                  subject: project,
                  team: team,
                  message_items: { random_item: 'random_item_value' })

        expect(custom_call.activity.message_items[:random_item])
          .to be == 'random_item_value'
      end

      it 'adds string to message items' do
        activity = Activities::CreateActivityService
                   .call(activity_type: :create_project,
                           owner: user,
                           subject: project,
                           team: team,
                           message_items: {
                             some_string: 'something'
                           }).activity

        expect(activity.message_items).to include(some_string: 'something')
      end
    end

    context 'when message item is object' do
      it 'transform message_item object to hash' do
        a = service_call.activity

        expect(a.message_items[:project].keys)
          .to contain_exactly(:type, :value, :id, :value_for)
      end

      it 'adds object project to message items as hash' do
        activity = Activities::CreateActivityService
                   .call(activity_type: :create_project,
                           owner: user,
                           subject: project,
                           team: team,
                           message_items: {
                             project: project.id
                           }).activity
        expect(activity.message_items).to include(project: be_an(Hash))
      end
    end

    context 'when message item is object with diffrent name' do
      it 'adds project_new to message items as hash' do
        activity = Activities::CreateActivityService
                   .call(activity_type: :create_project,
                           owner: user,
                           subject: project,
                           team: team,
                           message_items: {
                             project_withsuffix: project.id
                           }).activity
        expect(activity.message_items)
          .to include(project_withsuffix: be_an(Hash))
      end
    end

    context 'when message item is an object with custom value getter' do
      it 'adds project visibility to message items as hash' do
        project.update_attribute(:visibility, 'hidden')

        activity = Activities::CreateActivityService
                   .call(activity_type: :create_project,
                           owner: user,
                           subject: project,
                           team: team,
                           message_items: {
                             project_visibility: { id: project.id, value_for: 'visibility' }
                           }).activity

        expect(activity.message_items)
          .to include(project_visibility: { id: project.id,
                                            type: 'Project',
                                            value_for: 'visibility',
                                            value: project.visibility })
      end
    end

    context 'when message item is an Time object' do
      it 'adds time value and type to message items as hash' do
        project.update_attribute(:visibility, 'hidden')
        project.update_attribute(:due_date, Time.now)

        activity = Activities::CreateActivityService.call(activity_type: :create_project,
                                                          owner: user,
                                                          subject: project,
                                                          team: team,
                                                          message_items: {
                                                            project_duedate: project.due_date
                                                          }).activity

        expect(activity.message_items).to include(project_duedate: { type: 'Time', value: project.due_date.to_i })
      end
    end
  end
end
