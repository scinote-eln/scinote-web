# frozen_string_literal: true

require 'rails_helper'

describe GlobalSearch::LabelTemplateSerializer do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:routes) { Rails.application.routes.url_helpers }
  let(:created_at) { Time.zone.parse('2030-03-14 09:30') }

  def serialize(record)
    described_class.new(record.reload).attributes
  end

  context 'with a zebra label template' do
    let(:template) do
      ZebraLabelTemplate.create!(team: team, name: 'Sample label', content: '^XA^FDsample^FS^XZ',
                                 created_by: user, last_modified_by: user, created_at: created_at)
    end

    it 'exposes the id, name, label format and a date-only created_at' do
      attrs = serialize(template)

      expect(attrs).to include(id: template.id, name: 'Sample label', format: 'ZPL')
      expect(attrs[:created_at]).to eq I18n.l(created_at, format: :full_date)
      expect(attrs[:created_at]).not_to include('09:30')
    end

    it 'describes the creator with the avatar url' do
      expect(serialize(template)[:created_by]).to eq(
        name: user.name,
        avatar_url: routes.avatar_path(user, :icon_small)
      )
    end

    it 'links the team to its dashboard' do
      expect(serialize(template)[:team]).to eq(name: team.name, url: routes.dashboard_path(team: team))
    end

    it 'links the template to its label template page' do
      expect(serialize(template)[:url]).to eq routes.label_template_path(template)
    end
  end

  context 'with a template without a creator' do
    let(:template) { ZebraLabelTemplate.create!(team: team, name: 'Orphan label', content: '^XA^XZ') }

    it 'returns no creator name and no avatar' do
      expect(serialize(template)[:created_by]).to eq(name: nil, avatar_url: nil)
    end
  end

  context 'with a predefined Fluics label template' do
    let(:template) do
      FluicsLabelTemplate.create!(team: team, name: 'Fluics label', content: '^XA^XZ', created_by: user)
    end

    it 'reports the Fluics format and vendor as the creator' do
      attrs = serialize(template)

      expect(attrs[:format]).to eq 'Fluics'
      expect(attrs[:created_by]).to eq(name: 'Fluics GmbH', avatar_url: routes.avatar_path(user, :icon_small))
    end
  end
end
