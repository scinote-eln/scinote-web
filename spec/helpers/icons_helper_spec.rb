# frozen_string_literal: true

require 'rails_helper'

describe IconsHelper, type: :helper do
  let(:team) { create(:team, name: 'Acme Lab') }

  describe '#draw_custom_icon' do
    it 'draws the shared icon without a title' do
      result = helper.draw_custom_icon('i-shared')

      expect(result).to start_with '<svg class="fas-custom"'
      expect(result).to include 'fill="#A0A0A0"'
      expect(result).not_to include '<title>'
      expect(result).to be_html_safe
    end

    it 'adds the edit title with the team name for a shared edit icon' do
      result = helper.draw_custom_icon('shared-edit', team)

      expect(result).to include "<title>#{I18n.t('repositories.icon_title.shared_edit', team_name: 'Acme Lab')}</title>"
      expect(result).to include 'fill-rule="evenodd"'
    end

    it 'adds the read title with the team name for a shared read icon' do
      result = helper.draw_custom_icon('shared-read', team)

      expect(result).to include "<title>#{I18n.t('repositories.icon_title.shared_read', team_name: 'Acme Lab')}</title>"
    end

    it 'returns the task icon as a complete svg' do
      result = helper.draw_custom_icon('task-icon')

      expect(result).to start_with '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"'
      expect(result).to include 'class="task-icon"'
      expect(result).to end_with '</svg>'
    end

    it 'wraps a known icon in the svg element exactly once' do
      result = helper.draw_custom_icon('i-shared')

      expect(result).to end_with '</svg>'
      expect(result.scan('<svg').size).to eq 1
    end

    it 'draws an empty icon for an unknown icon name without echoing the name' do
      pending 'bug: an unknown icon name is echoed unescaped as svg text instead of drawing an empty icon'

      result = helper.draw_custom_icon('unknown')

      expect(result).to start_with '<svg class="fas-custom" xmlns="http://www.w3.org/2000/svg" fill="none"'
      expect(result).not_to include 'unknown'
    end
  end
end
