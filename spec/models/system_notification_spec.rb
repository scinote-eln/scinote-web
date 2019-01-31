# frozen_string_literal: true

require 'rails_helper'

describe SystemNotification do
  subject(:system_notification) { build :system_notification }

  it 'is valid' do
    expect(system_notification).to be_valid
  end

  describe 'Validations' do
    describe '#title' do
      it { is_expected.to validate_presence_of(:title) }
    end

    describe '#modal_title' do
      it { is_expected.to validate_presence_of(:modal_title) }
    end

    describe '#modal_body' do
      it { is_expected.to validate_presence_of(:modal_body) }
    end

    describe '#description' do
      it { is_expected.to validate_presence_of(:description) }
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
end
