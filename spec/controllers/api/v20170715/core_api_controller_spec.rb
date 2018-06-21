require 'rails_helper'

describe Api::V20170715::CoreApiController, type: :controller do
  let!(:user) { create :user }
  let!(:team) { create :team, created_by: user }
  let(:task) { create :my_module }
  let(:sample1) { create :sample }
  let(:sample2) { create :sample }
  let(:sample3) { create :sample }
  before do
    task.samples << [sample1, sample2, sample3]
    UserProject.create!(user: user, project: task.experiment.project, role: 0)
  end

  describe 'GET #tasks_tree' do
    let!(:user_team) { create :user_team, team: team, user: user }
    context 'When valid request' do
      before do
        request.headers['HTTP_ACCEPT'] = 'application/json'
        request.headers['Authorization'] = 'Bearer ' + generate_token(user.id)
        get :tasks_tree
      end

      it 'Returns HTTP success' do
        expect(response).to have_http_status(200)
      end

      it 'Returns JSON body containing expected Task tree' do
        team = user.teams.first
        experiment = task.experiment
        project = experiment.project
        hash_body = nil
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body).to match(
          ['name' => team.name,
           'description' => team.description,
           'team_id' => team.id.to_s,
           'projects' => [{
             'name' => project.name,
             'visibility' => project.visibility,
             'archived' => project.archived,
             'project_id' => project.id.to_s,
             'experiments' => [{
               'name' => experiment.name,
               'description' => experiment.description,
               'archived' => experiment.archived,
               'experiment_id' => experiment.id.to_s,
               'tasks' => [{
                 'name' => task.name,
                 'description' => task.description,
                 'archived' => task.archived,
                 'task_id' => task.id.to_s,
                 'editable' => true
               }]
             }]
           }]]
        )
      end
    end

    context 'When invalid request' do
      context 'When invalid token' do
        before do
          request.headers['HTTP_ACCEPT'] = 'application/json'
          request.headers['Authorization'] = 'Bearer WroNgToken'
          get :tasks_tree
        end

        it 'Returns HTTP unauthorized' do
          expect(response).to have_http_status(401)
        end
      end
    end
  end
end
