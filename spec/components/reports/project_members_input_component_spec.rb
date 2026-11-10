# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::ProjectMembersInputComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:owner) { create :user, full_name: 'Olga Owner' }
  let(:team) { create :team, created_by: owner }
  let(:project) { create :project, team: team, created_by: owner }
  let(:member) { create :user, full_name: 'Mark Member' }
  let(:report) { create :report, user: owner, project: project, team: team }
  let(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }

  before do
    member.update!(job_title: 'Chemist')
    create :user_assignment, user: member, assignable: project, user_role: viewer_role, assigned_by: owner
  end

  def render_component(**opts)
    render_inline(described_class.new(report: report, name: 'people', label: 'People', **opts))
  end

  def add_value(ids)
    report.report_template_values.create!(view_component: 'ProjectMembersInputComponent', name: 'people', value: ids)
  end

  context 'when editing' do
    it 'renders a multiple select with an option for every project member carrying the job title' do
      page = render_component(job_title_element_target: '#title')
      select = page.at_css('select[name="people[]"]')
      expect(select['multiple']).to be_present
      expect(select['data-type']).to eq 'ProjectMembersInputComponent'
      expect(select['data-job-title-element-target']).to eq '#title'
      option = select.css('option').find { |o| o['value'] == member.id.to_s }
      expect(option.text).to eq 'Mark Member'
      expect(JSON.parse(option['data-params'])).to eq('job_title' => 'Chemist')
      expect(select.css('option').map { |o| o['value'] }).to include(owner.id.to_s)
    end

    it 'preselects the stored members' do
      add_value([member.id])
      selected = render_component.css('option[selected]').map { |o| o['value'] }
      expect(selected).to eq [member.id.to_s]
    end
  end

  context 'when not editing' do
    it 'lists the stored members by full name' do
      add_value([member.id])
      page = render_component(editing: false)
      expect(page.text.strip).to eq 'Mark Member'
    end

    it 'lists the member by another displayed field' do
      add_value([member.id])
      page = render_component(editing: false, displayed_field: :job_title)
      expect(page.text.strip).to eq 'Chemist'
    end

    it 'ignores users that are not project members' do
      outsider = create :user, full_name: 'Out Sider'
      add_value([outsider.id])
      expect(render_component(editing: false).text.strip).to eq ''
    end
  end
end
