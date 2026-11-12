# frozen_string_literal: true

require 'rails_helper'

describe LabelPrintersController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:printer) do
    LabelPrinter.create!(name: 'Printer 1', description: 'Lab', type_of: :fluics, language_type: :zpl,
                         fluics_api_key: 'key-1', fluics_lid: 'LID1')
  end

  describe 'GET index' do
    it 'lists printers as json' do
      get :index, format: :json
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Printer 1')
    end

    it 'renders the html index' do
      get :index
      expect(response).to render_template('index')
      expect(assigns(:fluics_api_key)).to eq 'key-1'
      expect(assigns(:printer_type)).to eq 'fluics'
    end

    it 'has no api key when there are no printers' do
      LabelPrinter.destroy_all
      get :index
      expect(assigns(:fluics_api_key)).to be_nil
    end
  end

  describe 'GET index_zebra' do
    it 'renders the index for zebra printers' do
      get :index_zebra
      expect(response).to render_template('index')
      expect(assigns(:printer_type)).to eq 'zebra'
    end
  end

  describe 'GET new / edit' do
    # bug: app/views/label_printers has no new/edit templates, so both actions raise MissingTemplate
    it 'raises MissingTemplate for new' do
      expect { get :new }.to raise_error(ActionController::MissingExactTemplate)
    end

    it 'raises MissingTemplate for edit' do
      expect { get :edit, params: { id: printer.id } }.to raise_error(ActionController::MissingExactTemplate)
    end
  end

  describe 'POST create' do
    it 'creates a printer and redirects to edit' do
      expect do
        post :create, params: { label_printer: { name: 'New printer', type_of: 'fluics', language_type: 'zpl' } }
      end.to change(LabelPrinter, :count).by(1)

      created = LabelPrinter.find_by!(name: 'New printer')
      expect(created).to have_attributes(type_of: 'fluics', language_type: 'zpl')
      expect(response).to redirect_to(edit_label_printer_path(created))
      expect(flash[:success]).to be_present
    end

    # bug: failure branch renders :new which has no template
    it 'does not create an invalid printer and fails to render new' do
      expect do
        expect do
          post :create, params: { label_printer: { name: '', type_of: 'fluics' } }
        end.to raise_error(ActionView::MissingTemplate)
      end.not_to change(LabelPrinter, :count)
      expect(flash[:error]).to be_present
    end
  end

  describe 'PUT update' do
    it 'updates the printer' do
      put :update, params: { id: printer.id, label_printer: { name: 'Renamed' } }
      expect(printer.reload.name).to eq 'Renamed'
      expect(response).to redirect_to(edit_label_printer_path(printer))
      expect(flash[:success]).to be_present
    end

    # bug: failure branch renders :edit which has no template
    it 'does not apply invalid data and fails to render edit' do
      expect do
        put :update, params: { id: printer.id, label_printer: { name: '' } }
      end.to raise_error(ActionView::MissingTemplate)
      expect(printer.reload.name).to eq 'Printer 1'
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the printer' do
      expect { delete :destroy, params: { id: printer.id } }.to change(LabelPrinter, :count).by(-1)
      expect(response).to redirect_to(addons_path)
      expect(flash[:success]).to be_present
    end

    it 'flashes an error when destroy fails' do
      allow_any_instance_of(LabelPrinter).to receive(:destroy).and_return(false)
      expect { delete :destroy, params: { id: printer.id } }.not_to change(LabelPrinter, :count)
      expect(flash[:error]).to be_present
    end
  end

  describe 'POST create_fluics' do
    let(:client) { instance_double(LabelPrinters::Fluics::ApiClient) }

    before { allow(LabelPrinters::Fluics::ApiClient).to receive(:new).with('new-key').and_return(client) }

    it 'replaces printers with the ones returned by the api' do
      allow(client).to receive(:list).and_return([{ 'LID' => 'L9', 'serviceName' => 'Fluics 9', 'comment' => 'c' }])
      post :create_fluics, params: { label_printer: { fluics_api_key: 'new-key' } }
      expect(response).to redirect_to(label_printers_path)
      expect(LabelPrinter.pluck(:name)).to eq ['Fluics 9']
      expect(LabelPrinter.first.fluics_api_key).to eq 'new-key'
    end

    it 'flashes an error on a bad api key and keeps the printers' do
      allow(client).to receive(:list).and_raise(LabelPrinters::Fluics::ApiClient::BadRequestError)
      post :create_fluics, params: { label_printer: { fluics_api_key: 'new-key' } }
      expect(flash[:error]).to eq I18n.t('users.settings.account.label_printer.api_key_error')
      expect(LabelPrinter.pluck(:name)).to eq ['Printer 1']
    end
  end

  describe 'GET update_progress_modal' do
    it 'returns the rendered modal html' do
      get :update_progress_modal, params: { id: printer.id, starting_item_count: 3 }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
    end
  end

  describe 'retired print endpoint' do
    # printing goes through repository_rows#print; this one could never work and was removed
    it 'is no longer routed' do
      expect(Rails.application.routes.url_helpers).not_to respond_to(:print_label_printer_path)
    end
  end
end
