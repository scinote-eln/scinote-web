# frozen_string_literal: true

require 'rails_helper'

describe EditingFlagCleanupJob, type: :job do
  let!(:active_editing_flag) { create :editing_flag, timeout_at: 1.minute.from_now }
  let!(:expired_editing_flag) { create :editing_flag, timeout_at: 1.minute.ago }

  it 'destroys only the expired editing flags' do
    expect { described_class.perform_now }.to change(EditingFlag, :count).by(-1)
    expect(EditingFlag.exists?(expired_editing_flag.id)).to be(false)
    expect(EditingFlag.exists?(active_editing_flag.id)).to be(true)
  end

  context 'when an expired flag is orphaned (its subject was already destroyed)' do
    let!(:orphaned_subject) { create :step }
    let!(:orphaned_editing_flag) { create :editing_flag, subject: orphaned_subject, timeout_at: 1.minute.ago }

    before { orphaned_subject.destroy }

    it 'still destroys it, and does not abort cleanup of the other expired flags' do
      expect { described_class.perform_now }.not_to raise_error

      expect(EditingFlag.exists?(orphaned_editing_flag.id)).to be(false)
      expect(EditingFlag.exists?(expired_editing_flag.id)).to be(false)
      expect(EditingFlag.exists?(active_editing_flag.id)).to be(true)
    end
  end
end
