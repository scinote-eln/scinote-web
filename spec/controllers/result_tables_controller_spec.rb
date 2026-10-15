# frozen_string_literal: true

require 'rails_helper'

# ResultTablesController is the legacy controller; only #download is routed, so
# #edit and #update are exercised through temporarily drawn routes.
describe ResultTablesController, type: :controller do
  login_user

  include_context 'reference_project_structure', { record_deletion_enabled: true }

  let!(:result) { create :result, my_module: my_module, user: user, name: 'Result tbl' }
  let(:table) { create :table, team: team, created_by: user, contents: { data: [%w(a b), %w(c d)] }.to_json }
  let!(:result_table) { create :result_table, result: result, table: table }

  def downgrade_to_viewer
    UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                  .update_all(user_role_id: viewer_role.id)
  end

  def draw_routes(&block)
    set = ActionDispatch::Routing::RouteSet.new
    original_routes = @routes
    begin
      set.draw do
        get 'result_tables/:id/download', to: 'result_tables#download', as: :result_table_download
        resources :result_tables, only: %i(edit update)
        get 'my_modules/:id/results', to: 'my_modules#results', as: :results_my_module
      end
      @routes = set
      instance_exec(&block)
    ensure
      @routes = original_routes
    end
  end

  describe 'GET #download' do
    render_views

    it 'sends the table as tab separated text named after the result' do
      draw_routes do
        get :download, params: { id: result_table.id }
        expect(response).to have_http_status(:ok)
        expect(response.body.lines.map(&:chomp).reject(&:empty?)).to eq ["a\tb", "c\td"]
        expect(response.headers['Content-Disposition']).to include('Result tbl.txt')
      end
    end

    it 'sends an empty file when the table has no data key' do
      table.update_column(:contents, '{}')
      draw_routes do
        get :download, params: { id: result_table.id }
        expect(response).to have_http_status(:ok)
        expect(response.body.strip).to eq ''
      end
    end

    it 'returns 404 for an unknown table' do
      draw_routes do
        get :download, params: { id: 0 }
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns forbidden when the user cannot read the result' do
      draw_routes do
        without_partial_double_verification do
          allow(controller).to receive(:can_read_result?).and_return(false)
        end
        get :download, params: { id: result_table.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #edit' do
    render_views

    it 'returns forbidden for a viewer' do
      draw_routes do
        downgrade_to_viewer
        get :edit, params: { id: result_table.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'renders the edit form html' do
      pending 'bug: edit partial uses Result#table which no longer exists'
      draw_routes do
        get :edit, params: { id: result_table.id }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['html']).to include('table-form')
      end
    end
  end

  describe 'PUT #update' do
    before { allow(Activities::CreateActivityService).to receive(:call) }

    it 'returns forbidden for a viewer' do
      draw_routes do
        downgrade_to_viewer
        put :update, params: { id: result_table.id, result: { name: 'Nope' } }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'returns forbidden when archiving without manage permission' do
      draw_routes do
        downgrade_to_viewer
        put :update, params: { id: result_table.id, result: { archived: 'true' } }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'renames the result and logs an edit activity' do
      pending 'bug: update uses Result#table which no longer exists (NoMethodError)'
      draw_routes do
        put :update, params: { id: result_table.id, result: { name: 'Renamed' } }, format: :json
        expect(response).to have_http_status(:ok)
        expect(result.reload.name).to eq 'Renamed'
        expect(Activities::CreateActivityService).to have_received(:call)
          .with(hash_including(activity_type: :edit_result))
      end
    end

    it 'returns 404 for an unknown table' do
      draw_routes do
        put :update, params: { id: 0, result: { name: 'x' } }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
