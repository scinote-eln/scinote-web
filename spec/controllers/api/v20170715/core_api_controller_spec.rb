require 'rails_helper'

describe Api::V20170715::CoreApiController, type: :controller do
  let(:user) { create(:user) }
  let(:task) { create(:my_module) }
  let(:sample1) { create(:sample) }
  let(:sample2) { create(:sample) }
  let(:sample3) { create(:sample) }
  before do
    task.samples << [sample1, sample2, sample3]
    UserProject.create!(user: user, project: task.experiment.project, role: 0)
  end

  describe 'GET #task_samples' do
    context 'When valid request' do
      before do
        request.headers['HTTP_ACCEPT'] = 'application/json'
        request.headers['Authorization'] = 'Bearer ' + generate_token(user.id)
        get :task_samples, params: { task_id: task.id }
      end

      it 'Returns HTTP success' do
        expect(response).to have_http_status(200)
      end

      it 'Returns JSON body containing expected Samples' do
        hash_body = nil
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body).to match(
          [{ 'sample_id' => sample1.id.to_s, 'name' => sample1.name },
           { 'sample_id' => sample2.id.to_s, 'name' => sample2.name },
           { 'sample_id' => sample3.id.to_s, 'name' => sample3.name }]
        )
      end
    end

    context 'When invalid request' do
      context 'When invalid token' do
        before do
          request.headers['HTTP_ACCEPT'] = 'application/json'
          request.headers['Authorization'] = 'Bearer WroNgToken'
          get :task_samples, params: { task_id: task.id }
        end

        it 'Returns HTTP unauthorized' do
          expect(response).to have_http_status(401)
        end
      end

      context 'When valid token, but invalid request' do
        before do
          request.headers['HTTP_ACCEPT'] = 'application/json'
          request.headers['Authorization'] = 'Bearer ' + generate_token(user.id)
        end

        it 'Returns HTTP not found' do
          get :task_samples, params: { task_id: 1000 }
          expect(response).to have_http_status(404)
          expect(json).to match({})
        end

        it 'Returns HTTP access denied' do
          UserProject.where(user: user, project: task.experiment.project)
                     .first
                     .destroy!
          get :task_samples, params: { task_id: task.id }
          expect(response).to have_http_status(403)
          expect(json).to match({})
        end
      end
    end
  end

  describe 'GET #tasks_tree' do
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
          ['team_id' => team.id.to_s, 'name' => team.name,
           'description' => team.description,
           'projects' => [{
             'project_id' => project.id.to_s, 'name' => project.name,
             'visibility' => project.visibility,
             'archived' => project.archived,
             'experiments' => [{
               'experiment_id' => experiment.id.to_s,
               'name' => experiment.name,
               'description' => experiment.description,
               'archived' => experiment.archived,
               'tasks' => [{
                 'task_id' => task.id.to_s, 'name' => task.name,
                 'description' => task.description,
                 'archived' => task.archived
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
