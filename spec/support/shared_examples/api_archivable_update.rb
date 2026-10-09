# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
# Expects `action` (performing the update request with `request_body`), `archivable` and `archiving_user` to be defined.
RSpec.shared_examples 'an API update with archived attribute' do |type, other_attributes|
  let(:request_body) { { data: { type: type, attributes: attributes } } }

  context 'when archiving an active record' do
    let(:attributes) { { archived: true } }

    it 'archives the record' do
      action

      expect(response).to have_http_status 200
      expect(archivable.reload).to be_archived
      expect(archivable.archived_by).to eq archiving_user
      expect(json['data']['attributes']['archived']).to be true
    end
  end

  context 'when archiving together with other attributes' do
    let(:attributes) { other_attributes.merge(archived: true) }

    it 'archives the record and updates the other attributes' do
      action

      expect(response).to have_http_status 200
      archivable.reload
      expect(archivable).to be_archived
      other_attributes.each { |attribute, value| expect(archivable.public_send(attribute)).to eq value }
    end
  end

  context 'when restoring an archived record' do
    let(:attributes) { { archived: false } }

    before { archivable.archive!(archiving_user) }

    it 'restores the record' do
      action

      expect(response).to have_http_status 200
      expect(archivable.reload).to be_active
      expect(archivable.restored_by).to eq archiving_user
    end
  end

  context 'when restoring with a string value' do
    let(:attributes) { { archived: 'false' } }

    before { archivable.archive!(archiving_user) }

    it 'restores the record' do
      action

      expect(response).to have_http_status 200
      expect(archivable.reload).to be_active
    end
  end

  context 'when restoring together with other attributes' do
    let(:attributes) { other_attributes.merge(archived: false) }

    before { archivable.archive!(archiving_user) }

    it 'renders 403 and keeps the record archived' do
      action

      expect(response).to have_http_status 403
      expect(archivable.reload).to be_archived
    end
  end

  context 'when updating other attributes of an archived record' do
    let(:attributes) { other_attributes }

    before { archivable.archive!(archiving_user) }

    it 'renders 403' do
      action

      expect(response).to have_http_status 403
    end
  end

  context 'when the record is already in the requested state' do
    let(:attributes) { { archived: true } }

    before { archivable.archive!(archiving_user) }

    it 'renders 204 and does not touch the record' do
      expect { action }.not_to(change { archivable.reload.updated_at })
      expect(response).to have_http_status 204
    end
  end

  context 'when archived is not sent' do
    let(:attributes) { other_attributes }

    it 'does not change the archived state' do
      action

      expect(response).to have_http_status 200
      expect(archivable.reload).to be_active
    end
  end
end
# rubocop:enable Metrics/BlockLength
