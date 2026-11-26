# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumnSerializer do
  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:column) { create :repository_column, :text_type, repository: repository, created_by: user, mandatory: true }
  let(:repository_snapshot) { RepositorySnapshot.create_preliminary!(repository, create(:my_module), user) }
  let(:snapshot_column) { column.snapshot!(repository_snapshot) }

  def serialized_mandatory(repository_column)
    described_class.new(repository_column).as_json[:mandatory]
  end

  describe '#mandatory' do
    it 'exposes the mandatory flag of an inventory column' do
      expect(serialized_mandatory(column)).to be true
    end

    it 'exposes the mandatory flag a snapshot column was copied with' do
      expect(serialized_mandatory(snapshot_column)).to be true
    end

    it 'exposes a snapshot column that is not mandatory as such' do
      column.update!(mandatory: false)

      expect(serialized_mandatory(snapshot_column)).to be false
    end

    context 'when inventory integrity is disabled' do
      before { allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(false) }

      it 'hides the mandatory flag of a snapshot column without changing it' do
        expect(serialized_mandatory(snapshot_column)).to be false
        expect(snapshot_column.reload.mandatory).to be true
      end
    end
  end
end
