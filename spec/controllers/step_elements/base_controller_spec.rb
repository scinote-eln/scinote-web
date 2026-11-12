# frozen_string_literal: true

require 'rails_helper'

# Covers the abstract defaults of StepElements::BaseController that every concrete controller overrides
describe StepElements::BaseController, type: :controller do
  let(:base) { described_class.new }

  describe 'abstract hooks' do
    %i(log_archive_activity log_restore_activity content_block_type).each do |hook|
      it "#{hook} must be implemented by subclasses" do
        expect { base.send(hook) }.to raise_error(NotImplementedError)
      end
    end

    it 'responds with a plain ok on restore by default' do
      expect(base).to receive(:head).with(:ok)

      base.send(:restore_response)
    end
  end

  describe 'default permission checks' do
    it 'denies locking and unlocking unless a subclass grants it' do
      expect(base).to receive(:render_403).twice

      base.send(:check_lock_permissions)
      base.send(:check_unlock_permissions)
    end

    it 'renders 403 when the user cannot manage the step' do
      step = create :step, protocol: create(:protocol, :in_repository_draft, added_by: create(:user))
      base.instance_variable_set(:@step, step)
      allow(base).to receive(:can_manage_step?).with(step).and_return(false)
      expect(base).to receive(:render_403)

      base.send(:check_manage_step_permissions)
    end

    it 'allows managers through' do
      step = create :step, protocol: create(:protocol, :in_repository_draft, added_by: create(:user))
      base.instance_variable_set(:@step, step)
      allow(base).to receive(:can_manage_step?).with(step).and_return(true)
      expect(base).not_to receive(:render_403)

      base.send(:check_manage_step_permissions)
    end
  end
end
