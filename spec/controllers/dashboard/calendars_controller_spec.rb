# frozen_string_literal: true

require 'rails_helper'

describe Dashboard::CalendarsController, type: :controller do
  login_user
  render_views

  before(:all) { MyModuleStatusFlow.ensure_default }

  include_context 'reference_project_structure', { my_modules: 1 }

  let(:json) { JSON.parse(response.body) }
  let(:date) { Date.new(2030, 5, 15) }

  before { user.update!(current_team_id: team.id) }

  describe 'GET show' do
    it 'returns due dates of readable active tasks around the month' do
      my_module.update!(due_date: date.in_time_zone + 10.hours)

      get :show, params: { date: date.to_s }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['events']).to eq [{ 'date' => date.to_s }]
    end

    it 'includes dates in the surrounding calendar weeks' do
      my_module.update!(due_date: Date.new(2030, 6, 10).in_time_zone + 10.hours)

      get :show, params: { date: date.to_s }, format: :json

      expect(json['events']).to eq [{ 'date' => '2030-06-10' }]
    end

    it 'ignores tasks outside of the range' do
      my_module.update!(due_date: Date.new(2031, 1, 1).in_time_zone + 10.hours)

      get :show, params: { date: date.to_s }, format: :json

      expect(json['events']).to eq []
    end

    it 'ignores tasks of archived projects' do
      my_module.update!(due_date: date.in_time_zone + 10.hours)
      project.update_columns(archived: true)

      get :show, params: { date: date.to_s }, format: :json

      expect(json['events']).to eq []
    end

    it 'ignores tasks of archived experiments' do
      my_module.update!(due_date: date.in_time_zone + 10.hours)
      experiment.update_columns(archived: true)

      get :show, params: { date: date.to_s }, format: :json

      expect(json['events']).to eq []
    end
  end

  describe 'GET day' do
    it 'renders the tasks due on that day' do
      my_module.update!(due_date: date.in_time_zone + 10.hours)

      get :day, params: { date: date.to_s }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['html']).to include(my_module.name, project.name, experiment.name)
    end

    it 'renders the empty placeholder when nothing is due' do
      get :day, params: { date: date.to_s }, format: :json

      expect(json['html']).to include('no-results-placeholder')
      expect(json['html']).not_to include(my_module.name)
    end

    it 'does not render tasks due on another day' do
      my_module.update!(due_date: (date + 1.day).in_time_zone + 10.hours)

      get :day, params: { date: date.to_s }, format: :json

      expect(json['html']).not_to include(my_module.name)
    end
  end
end
