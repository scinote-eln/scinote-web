# frozen_string_literal: true

require 'rails_helper'

describe ResultTemplateOrderableElementsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, :record_deletion_enabled, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:result_template) { create :result_template, protocol: protocol, user: user }
  let!(:text_one) { create :result_text, result: result_template }
  let!(:text_two) { create :result_text, result: result_template }
  let!(:element_one) { create :result_orderable_element, result: result_template, orderable: text_one, position: 0 }
  let!(:element_two) { create :result_orderable_element, result: result_template, orderable: text_two, position: 1 }
  let(:positions) { { element_one.id.to_s => 1, element_two.id.to_s => 0 } }

  describe 'POST reorder' do
    it 'updates the element positions of the template' do
      post :reorder, params: { protocol_id: protocol.id, result_template_id: result_template.id,
                               result_orderable_element_positions: positions }
      expect(response).to have_http_status(:ok)
      expect(element_one.reload.position).to eq 1
      expect(element_two.reload.position).to eq 0
    end

    it 'returns 404 for an unknown result template' do
      post :reorder, params: { protocol_id: protocol.id, result_template_id: 0,
                               result_orderable_element_positions: positions }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns forbidden when the user cannot manage the template' do
      without_partial_double_verification do
        allow(controller).to receive(:can_manage_result?).and_return(false)
      end
      post :reorder, params: { protocol_id: protocol.id, result_template_id: result_template.id,
                               result_orderable_element_positions: positions }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
