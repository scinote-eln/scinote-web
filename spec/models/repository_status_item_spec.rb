# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStatusItem do
  let(:repository_status_item) { build :repository_status_item }

  it 'is valid' do
    expect(repository_status_item).to be_valid
  end

  describe 'Validations' do
    describe '#repository' do
      it { is_expected.to validate_presence_of(:repository) }
    end

    describe '#icon' do
      it { is_expected.to validate_presence_of(:icon) }
    end

    describe '#status' do
      it { is_expected.to validate_presence_of(:status) }
      it { is_expected.to validate_length_of(:status).is_at_most(255) }
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:repository) }
    it { is_expected.to belong_to(:repository_column) }
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
    it { is_expected.to have_many(:repository_status_values) }
  end
end
