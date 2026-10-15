# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotationsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  let(:json) { JSON.parse(response.body) }

  def tag_for(type, record)
    "#~#{type}~#{record.id.base62_encode}"
  end

  before { user.update!(current_team_id: team.id) }

  describe 'GET show' do
    it 'returns 404 when the tag has no type' do
      get :show, params: { tag: '#', data: true }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown type' do
      get :show, params: { tag: "#~xyz~#{project.id.base62_encode}", data: true }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when the record does not exist' do
      get :show, params: { tag: "#~prj~#{(project.id + 100_000).base62_encode}", data: true }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    context 'with data' do
      it 'returns name and type of a project' do
        get :show, params: { tag: tag_for('prj', project), data: true }, format: :json
        expect(json).to eq('name' => project.name, 'type' => 'prj')
      end

      it 'returns name and type of an experiment' do
        get :show, params: { tag: tag_for('exp', experiment), data: true }, format: :json
        expect(json).to eq('name' => experiment.name, 'type' => 'exp')
      end

      it 'returns name and type of a task' do
        get :show, params: { tag: tag_for('tsk', my_module), data: true }, format: :json
        expect(json).to eq('name' => my_module.name, 'type' => 'tsk')
      end

      it 'returns false name for an unreadable project' do
        foreign = create :project, team: create(:team, created_by: create(:user)), created_by: create(:user)
        get :show, params: { tag: tag_for('prj', foreign), data: true }, format: :json
        expect(json['name']).to be false
      end

      context 'with repository rows' do
        let(:repository) { create :repository, team: team, created_by: user, name: 'Big Sample Store' }
        let(:row) { create :repository_row, repository: repository, created_by: user }

        it 'returns name and acronym of a three-word repository' do
          get :show, params: { tag: tag_for('rep_item', row), data: true }, format: :json
          expect(json).to eq('name' => row.name, 'type' => 'Bss')
        end

        it 'builds the acronym from one word' do
          repository.update!(name: 'Samples')
          get :show, params: { tag: tag_for('rep_item', row), data: true }, format: :json
          expect(json['type']).to eq 'Sam'
        end

        it 'builds the acronym from two words' do
          repository.update!(name: 'Big Store')
          get :show, params: { tag: tag_for('rep_item', row), data: true }, format: :json
          expect(json['type']).to eq 'Bis'
        end

        it 'returns false name for an unreadable repository' do
          foreign_row = create :repository_row, created_by: create(:user)
          get :show, params: { tag: tag_for('rep_item', foreign_row), data: true }, format: :json
          expect(json['name']).to be false
        end
      end
    end

    context 'without data' do
      it 'redirects to the project experiments' do
        get :show, params: { tag: tag_for('prj', project) }, format: :json
        expect(response).to redirect_to(experiments_path(project_id: project.id))
      end

      it 'redirects to the experiment tasks' do
        get :show, params: { tag: tag_for('exp', experiment) }, format: :json
        expect(response).to redirect_to(my_modules_experiment_path(experiment))
      end

      it 'redirects to the task protocol' do
        get :show, params: { tag: tag_for('tsk', my_module) }, format: :json
        expect(response).to redirect_to(protocols_my_module_path(my_module))
      end

      it 'redirects to the repository row' do
        repository = create :repository, team: team, created_by: user
        row = create :repository_row, repository: repository, created_by: user
        get :show, params: { tag: tag_for('rep_item', row), my_module_id: my_module.id }, format: :json
        expect(response).to redirect_to(
          repository_repository_row_path(repository, row, my_module_id: my_module.id)
        )
      end
    end
  end

  describe 'GET user' do
    it 'returns 404 for an unknown user' do
      get :user, params: { tag: "@~#{(user.id + 100_000).base62_encode}" }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns profile info with role and team for a team member' do
      member = create :user, full_name: 'Team Member'
      create :user_assignment, user: member, assignable: team, user_role: owner_role
      get :user, params: { tag: "@~#{member.id.base62_encode}" }, format: :json
      expect(json).to include('name' => 'Team Member', 'email' => member.email)
      expect(json['avatar_url']).to be_present
      expect(json['info']).to include(team.name, owner_role.name.capitalize)
    end

    it 'returns the not in this team info for an outsider' do
      outsider = create :user
      get :user, params: { tag: "@~#{outsider.id.base62_encode}" }, format: :json
      expect(json['info']).to include(I18n.t('atwho.users.not_in_this_team'))
    end
  end
end
