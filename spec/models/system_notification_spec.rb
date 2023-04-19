# frozen_string_literal: true

require 'rails_helper'

describe SystemNotification do
  let(:system_notification) { build :system_notification }

  it 'is valid' do
    expect(system_notification).to be_valid
  end

  describe 'Validations' do
    describe '#title' do
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_length_of(:title).is_at_most(255) }
    end

    describe '#modal_title' do
      it { is_expected.to validate_presence_of(:modal_title) }
      it { is_expected.to validate_length_of(:modal_title).is_at_most(255) }
    end

    describe '#modal_body' do
      it { is_expected.to validate_presence_of(:modal_body) }
      it { is_expected.to validate_length_of(:modal_body).is_at_most(100000) }
    end

    describe '#description' do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_length_of(:description).is_at_most(255) }
    end

    describe '#source_id' do
      it { is_expected.to validate_presence_of(:source_id) }
    end

    describe '#source_created_at' do
      it { is_expected.to validate_presence_of(:source_created_at) }
    end

    describe '#last_time_changed_at' do
      it { is_expected.to validate_presence_of(:last_time_changed_at) }
    end
  end

  describe 'Associations' do
    it { is_expected.to have_many(:users) }
  end

  describe 'self.last_sync_timestamp' do
    context 'when there is no users or system notifications in db' do
      it 'returns nil' do
        expect(described_class.last_sync_timestamp).to be_nil
      end
    end

    context 'when there is no system notifications in db' do
      it 'returns first users created_at' do
        create :user
        create :user, created_at: Time.now + 5.seconds

        expect(described_class.last_sync_timestamp)
          .to be == User.first.created_at.to_i
      end
    end

    context 'when have some system notifications' do
      it 'returns last system notifications last_time_changed_at timestamp' do
        create :user
        create :system_notification

        expect(described_class.last_sync_timestamp)
          .to be SystemNotification.last.last_time_changed_at.to_i
      end
    end
  end
end
