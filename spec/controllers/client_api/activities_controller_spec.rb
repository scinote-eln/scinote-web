require 'rails_helper'

describe ClientApi::ActivitiesController, type: :controller, broken: true do
  login_user
  render_views

  before do
    project = create :project, created_by: User.first
    UserProject.create(user: User.first, project: project, role: 2)
    create :activity, user: User.first, project: project
  end

  describe '#index' do
    it 'returns a valid object' do
      get :index, format: :json
      expect(response.status).to eq(200)
      expect(response.body).to match_response_schema('activities')
    end
  end
end
