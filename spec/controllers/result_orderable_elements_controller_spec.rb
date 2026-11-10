# frozen_string_literal: true

require 'rails_helper'

describe ResultOrderableElementsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { record_deletion_enabled: true }

  let!(:result) { create :result, my_module: my_module, user: user }
  let!(:text_one) { create :result_text, result: result }
  let!(:text_two) { create :result_text, result: result }
  let!(:element_one) { create :result_orderable_element, result: result, orderable: text_one, position: 0 }
  let!(:element_two) { create :result_orderable_element, result: result, orderable: text_two, position: 1 }

  let(:positions) { { element_one.id.to_s => 1, element_two.id.to_s => 0 } }

  describe 'POST reorder' do
    let(:action) do
      post :reorder, params: { my_module_id: my_module.id, result_id: result.id,
                               result_orderable_element_positions: positions }
    end

    it 'updates the element positions and echoes them back' do
      action
      expect(response).to have_http_status(:ok)
      expect(element_one.reload.position).to eq 1
      expect(element_two.reload.position).to eq 0
      expect(response.parsed_body).to eq(positions.transform_values(&:to_s))
    end

    it 'logs a result_content_rearranged activity' do
      expect(Activities::CreateActivityService).to receive(:call).with(
        hash_including(activity_type: :result_content_rearranged, subject: result,
                       team: my_module.team,
                       message_items: { result: result.id, my_module: my_module.id })
      )
      action
    end

    it 'touches the result' do
      result.update_column(:updated_at, 1.day.ago)
      expect { action }.to(change { result.reload.updated_at })
    end

    it 'returns 404 for an unknown result' do
      post :reorder, params: { my_module_id: my_module.id, result_id: 0,
                               result_orderable_element_positions: positions }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns forbidden when the user cannot manage the result' do
      UserAssignment.where(user: user, assignable: [my_module, experiment, project])
                    .update_all(user_role_id: viewer_role.id)
      action
      expect(response).to have_http_status(:forbidden)
      expect(element_one.reload.position).to eq 0
    end
  end
end
