# frozen_string_literal: true

require 'rails_helper'

describe LabelTemplatesController, type: :controller do
  login_user

  # Upstream [SCI-13634]: templates of a team the user is not a member of are denied (predefined templates of the team).
  describe 'team scoping of permission checks' do
    let!(:user) { controller.current_user }
    let!(:team) { create :team, :change_user_team, created_by: user }
    let!(:other_team) { create :team }
    let(:own_template) { team.label_templates.find_by(type: 'ZebraLabelTemplate', default: true) }
    let(:other_team_template) { other_team.label_templates.find_by(type: 'ZebraLabelTemplate', default: true) }

    before do
      allow(LabelTemplate).to receive(:enabled?).and_return(true)
    end

    describe 'GET show' do
      it 'returns the label template from a team the user has access to' do
        get :show, params: { id: own_template.id }, format: :json

        expect(response).to have_http_status(:success)
      end

      it 'denies access to a label template from a team the user is not a member of' do
        get :show, params: { id: other_team_template.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PUT update' do
      let(:params) { { id: other_team_template.id, label_template: { name: 'Hijacked template' } } }

      it 'denies updating a label template from a team the user is not a member of' do
        put :update, params: params, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(other_team_template.reload.name).not_to eq('Hijacked template')
      end
    end

    describe 'POST set_default' do
      let(:non_default_template) { other_team.label_templates.find_by(type: 'ZebraLabelTemplate', default: false) }

      it 'denies setting default label template in a team the user is not a member of' do
        post :set_default, params: { id: non_default_template.id }, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(non_default_template.reload.default).to be(false)
      end
    end
  end

  # SCI-13582: every action with the real permission checks and their effects (starts from a team without templates).
  describe 'actions' do
    let!(:user) { subject.current_user }
    let!(:team) { create :team, created_by: user }
    let!(:viewer_role) { create :viewer_role }
    let(:settings_values) { { 'label_templates_enabled' => true } }

    def create_template(attrs = {})
      ZebraLabelTemplate.create!({ name: 'Zebra A', content: '^XA^XZ', width_mm: 25, height_mm: 12, unit: :mm,
                                   density: 12, team: team, created_by: user, last_modified_by: user }.merge(attrs))
    end

    def make_team_viewer!
      team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
    end

    before do
      LabelTemplate.where(team: team).destroy_all
      allow(ApplicationSettings).to receive(:instance)
        .and_return(instance_double(ApplicationSettings, values: settings_values))
    end

    describe 'GET index' do
      it 'lists templates of the current team as json' do
        create_template
        get :index, format: :json
        expect(response).to have_http_status(:success)
        names = JSON.parse(response.body)['data'].map { |d| d['attributes']['name'] }
        expect(names).to include('Zebra A')
      end

      it 'renders the index html when the feature is enabled' do
        get :index
        expect(response).to render_template('index')
      end

      context 'when the feature is disabled' do
        let(:settings_values) { {} }

        it 'renders the promo page' do
          get :index
          expect(response).to render_template(:promo)
        end

        it 'lists only predefined templates as json' do
          ZebraLabelTemplate.where(team: team).destroy_all
          create_template(name: 'custom')
          create_template(name: 'predef', predefined: true)
          get :index, format: :json
          names = JSON.parse(response.body)['data'].map { |d| d['attributes']['name'] }
          expect(names).to eq ['predef']
        end
      end
    end

    describe 'GET list' do
      it 'returns all templates of the team' do
        template = create_template
        get :list, format: :json
        expect(response).to have_http_status(:success)
        expect(response.body).to include(template.name)
      end
    end

    describe 'GET show' do
      let(:template) { create_template }

      it 'returns the template as json' do
        get :show, params: { id: template.id }, format: :json
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Zebra A')
      end

      it 'renders the html page' do
        get :show, params: { id: template.id }
        expect(response).to have_http_status(:success)
      end

      it 'switches the current team to the team of the template' do
        other_team = create :team, created_by: user
        other_template = create_template(team: other_team, name: 'Other')
        get :show, params: { id: other_template.id }, format: :json
        expect(response).to have_http_status(:success)
        expect(user.reload.current_team_id).to eq other_team.id
      end

      it 'renders promo when the feature is disabled' do
        allow(ApplicationSettings).to receive(:instance)
          .and_return(instance_double(ApplicationSettings, values: {}))
        get :show, params: { id: template.id }
        expect(response).to render_template(:promo)
      end
    end

    describe 'POST create' do
      it 'creates a default zebra template with an activity' do
        expect { post :create, format: :json }
          .to change(ZebraLabelTemplate, :count).by(1)
          .and change { Activity.where(type_of: :label_template_created).count }.by(1)
        created = ZebraLabelTemplate.order(:id).last
        expect(created.team).to eq team
        expect(created.created_by).to eq user
        expect(JSON.parse(response.body)['redirect_url']).to include("/label_templates/#{created.id}")
      end

      it 'is forbidden for a viewer' do
        make_team_viewer!
        expect { post :create, format: :json }.not_to change(LabelTemplate, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not render a body when saving fails' do
        allow_any_instance_of(ZebraLabelTemplate).to receive(:save!).and_raise(StandardError, 'boom')
        expect { post :create, format: :json }.not_to change(LabelTemplate, :count)
      end
    end

    describe 'PUT update' do
      let(:template) { create_template }

      it 'updates the template and logs an activity' do
        expect do
          put :update, params: { id: template.id, label_template: { name: 'Renamed', width_mm: 30 } }, format: :json
        end.to change { Activity.where(type_of: :label_template_edited).count }.by(1)
        expect(response).to have_http_status(:success)
        expect(template.reload.name).to eq 'Renamed'
        expect(template.last_modified_by).to eq user
      end

      it 'returns errors for invalid data' do
        put :update, params: { id: template.id, label_template: { name: '' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to have_key('name')
        expect(template.reload.name).to eq 'Zebra A'
      end

      it 'is forbidden for a viewer' do
        make_team_viewer!
        put :update, params: { id: template.id, label_template: { name: 'Renamed' } }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(template.reload.name).to eq 'Zebra A'
      end
    end

    describe 'POST duplicate' do
      let!(:template) { create_template }

      it 'duplicates selected templates and logs activities' do
        expect do
          post :duplicate, params: { selected_ids: [template.id] }, format: :json
        end.to change(ZebraLabelTemplate, :count).by(1)
           .and change { Activity.where(type_of: :label_template_copied).count }.by(1)
        expect(response).to have_http_status(:success)
        copy = ZebraLabelTemplate.find_by(name: 'Zebra A(1)')
        expect(copy.default).to be false
        expect(copy.predefined).to be false
      end

      it 'does not duplicate templates of other teams' do
        foreign = create_template(team: create(:team), name: 'Foreign')
        expect { post :duplicate, params: { selected_ids: [foreign.id] }, format: :json }
          .not_to change(LabelTemplate, :count)
      end

      it 'returns an error when duplication fails' do
        allow_any_instance_of(ZebraLabelTemplate).to receive(:save!).and_raise(StandardError, 'boom')
        post :duplicate, params: { selected_ids: [template.id] }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'is forbidden for a viewer' do
        make_team_viewer!
        expect { post :duplicate, params: { selected_ids: [template.id] }, format: :json }
          .not_to change(LabelTemplate, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'DELETE delete' do
      let!(:template) { create_template(name: 'To delete') }

      it 'destroys selected templates and logs activities' do
        expect do
          delete :delete, params: { selected_ids: [template.id] }, format: :json
        end.to change(LabelTemplate, :count).by(-1)
           .and change { Activity.where(type_of: :label_template_deleted).count }.by(1)
        expect(response).to have_http_status(:success)
      end

      it 'returns an error when destroy fails' do
        allow_any_instance_of(ZebraLabelTemplate).to receive(:destroy!).and_raise(StandardError, 'boom')
        delete :delete, params: { selected_ids: [template.id] }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'is forbidden for a viewer' do
        make_team_viewer!
        expect { delete :delete, params: { selected_ids: [template.id] }, format: :json }
          .not_to change(LabelTemplate, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST set_default' do
      let!(:old_default) { create_template(name: 'Old default', default: true) }
      let!(:template) { create_template(name: 'New default') }

      it 'moves the default flag to the selected template' do
        post :set_default, params: { id: template.id }, format: :json
        expect(response).to have_http_status(:success)
        expect(template.reload.default).to be true
        expect(old_default.reload.default).to be false
      end

      it 'returns an error when update fails' do
        allow_any_instance_of(ZebraLabelTemplate).to receive(:update!).and_raise(StandardError, 'boom')
        post :set_default, params: { id: template.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'is forbidden for a viewer' do
        make_team_viewer!
        post :set_default, params: { id: template.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(template.reload.default).to be false
      end
    end

    describe 'GET template_tags' do
      it 'returns the tags of the template' do
        template = create_template
        get :template_tags, params: { id: template.id }, format: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to be_present
      end
    end

    describe 'GET zpl_preview' do
      let(:service) { instance_double(LabelTemplatesPreviewService, error: nil) }

      before { allow(LabelTemplatesPreviewService).to receive(:new).and_return(service) }

      it 'returns the last generated image as base64' do
        allow(service).to receive(:generate_zpl_preview!).and_return("log line\nQUJD")
        get :zpl_preview, params: { zpl: '^XA^XZ', width: 1, height: 1, density: 12 }, format: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['base64_preview']).to eq 'QUJD'
      end

      it 'returns the service error' do
        allow(service).to receive(:generate_zpl_preview!).and_return('')
        allow(service).to receive(:error).and_return('bad zpl')
        get :zpl_preview, params: { zpl: 'x' }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq 'bad zpl'
      end
    end

    describe 'POST sync_fluics_templates' do
      let(:sync_service) { instance_double(LabelPrinters::Fluics::SyncService) }

      before { allow(LabelPrinters::Fluics::SyncService).to receive(:new).and_return(sync_service) }

      it 'syncs the templates' do
        expect(sync_service).to receive(:sync_templates!)
        post :sync_fluics_templates, format: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['message']).to eq I18n.t('label_templates.fluics.sync.success')
      end

      it 'returns an error when the sync fails' do
        allow(sync_service).to receive(:sync_templates!).and_raise(StandardError, 'down')
        post :sync_fluics_templates, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq I18n.t('label_templates.fluics.sync.error')
      end
    end

    describe 'POST actions_toolbar' do
      it 'returns the toolbar actions for the selected items' do
        template = create_template
        post :actions_toolbar, params: { items: [{ id: template.id }].to_json }, format: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to have_key('actions')
      end
    end
  end
end
