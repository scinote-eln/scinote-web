# frozen_string_literal: true

require 'rails_helper'

describe ReportsHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user, description: 'Experiment description' }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:report) { create :report, user: user, project: project, team: team }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }

  before do
    user.update!(current_team_id: team.id)
    create_user_assignment(team, owner_role, user)
    create_user_assignment(project, owner_role, user)
    without_partial_double_verification do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_team).and_return(team)
    end
    assign(:settings, {})
  end

  describe '#render_report_element' do
    def element_for(type, attrs = {})
      ReportElement.create!({ report: report, type_of: type, position: 1 }.merge(attrs))
    end

    it 'renders the partial of the element type with its record data' do
      html = helper.render_report_element(element_for(:experiment, experiment: experiment))

      expect(html).to include('report-experiment-element')
      expect(html).to include(experiment.name)
      expect(html).to include('Experiment description')
    end

    it 'renders active children inside the parent element' do
      parent = element_for(:project_header, project: project)
      other_experiment = create :experiment, project: project, created_by: user, name: 'Child experiment'
      create_user_assignment(other_experiment, owner_role, user)
      element_for(:experiment, experiment: other_experiment, parent: parent)

      html = helper.render_report_element(parent)

      expect(html).to include('report-element-children')
      expect(html).to include('Child experiment')
    end

    it 'skips children that are not active element types' do
      parent = element_for(:project_header, project: project)
      element_for(:step_comments, parent: parent, position: 2)

      expect(parent.children.active).to be_empty
      expect(helper.render_report_element(parent)).not_to include('report-step-comments')
    end

    it 'returns nil for an experiment the user cannot read' do
      foreign_experiment = create :experiment, created_by: create(:user)

      expect(helper.render_report_element(element_for(:experiment, experiment: foreign_experiment))).to be_nil
    end

    it 'returns nil for a task the user cannot read' do
      foreign_module = create :my_module, created_by: create(:user)

      expect(helper.render_report_element(element_for(:my_module, my_module: foreign_module))).to be_nil
    end

    it 'renders a task element the user can read' do
      MyModuleStatusFlow.ensure_default
      my_module.update!(my_module_status: MyModuleStatus.first)
      create_user_assignment(my_module, owner_role, user)

      expect(helper.render_report_element(element_for(:my_module, my_module: my_module))).to include(my_module.name)
    end

    it 'returns nil for an inventory the user cannot read' do
      foreign_repository = create :repository

      expect(helper.render_report_element(element_for(:my_module_repository, repository: foreign_repository))).to be_nil
    end

    it 'does not mutate the provided locals' do
      locals = { export_all: true }
      helper.render_report_element(element_for(:experiment, experiment: experiment), locals)

      expect(locals).to eq(export_all: true)
    end
  end

  describe '#report_image_asset_url' do
    let(:preview) { double('preview', processed: double('processed')) }
    let(:asset) { double('asset', inline?: true, large_preview: preview, medium_preview: preview) }

    it 'renders an image tag with the processed preview url' do
      allow(preview.processed).to receive(:url).with(expires_in: Constants::URL_LONG_EXPIRE_TIME)
                                               .and_return('https://example.com/preview.png')

      expect(helper.report_image_asset_url(asset)).to match(%r{<img[^>]+src="https://example.com/preview.png"})
    end

    it 'uses the medium preview for non-inline assets' do
      medium = double('medium', processed: double('processed', url: 'https://example.com/medium.png'))
      asset = double('asset', inline?: false, medium_preview: medium)

      expect(helper.report_image_asset_url(asset)).to include('https://example.com/medium.png')
    end

    it 'renders the missing icon when the file is not found' do
      allow(preview).to receive(:processed).and_raise(ActiveStorage::FileNotFoundError)

      expect(helper.report_image_asset_url(asset)).to include('missing')
    end

    it 'renders the generation error and logs it on other errors' do
      allow(preview).to receive(:processed).and_raise(StandardError, 'boom')
      expect(Rails.logger).to receive(:error).with('boom')

      expect(helper.report_image_asset_url(asset))
        .to eq "<i>#{I18n.t('projects.reports.index.generation.file_preview_generation_error')}</i>"
    end
  end

  describe '#assigned_repository_or_snapshot' do
    let(:repository) { create :repository, team: team, created_by: user }

    it 'returns the selected snapshot of the same parent for a snapshot' do
      snapshot = create :repository_snapshot, original_repository: repository, my_module: my_module, selected: true
      other = create :repository_snapshot, original_repository: repository, my_module: my_module, selected: false

      expect(helper.assigned_repository_or_snapshot(my_module, other)).to eq snapshot
    end

    it 'returns nil when the repository is not assigned to the task' do
      expect(helper.assigned_repository_or_snapshot(my_module, repository)).to be_nil
    end

    context 'when the repository is assigned' do
      before do
        row = create :repository_row, repository: repository, created_by: user
        create :mm_repository_row, repository_row: row, my_module: my_module, assigned_by: user
      end

      it 'returns the live repository when no snapshot is selected' do
        expect(helper.assigned_repository_or_snapshot(my_module, repository)).to eq repository
      end

      it 'returns the selected snapshot when there is one' do
        snapshot = create :repository_snapshot, original_repository: repository, my_module: my_module, selected: true

        expect(helper.assigned_repository_or_snapshot(my_module, repository)).to eq snapshot
      end
    end
  end

  describe '#step_status_label' do
    let(:step) { create :step, protocol: my_module.protocol, user: user }

    it 'labels a skipped step' do
      step.update!(skipped_at: Time.current, completed: false)

      expect(helper.step_status_label(step))
        .to eq "<span class=\"label step-label-default\">[#{I18n.t('protocols.steps.skipped')}]</span>"
    end

    it 'labels a completed step' do
      step.update!(completed: true, skipped_at: nil)

      expect(helper.step_status_label(step))
        .to eq "<span class=\"label step-label-success\">[#{I18n.t('protocols.steps.completed')}]</span>"
    end

    it 'labels an uncompleted step' do
      step.update!(completed: false, skipped_at: nil)

      expect(helper.step_status_label(step))
        .to eq "<span class=\"label step-label-default\">[#{I18n.t('protocols.steps.uncompleted')}]</span>"
    end
  end

  describe '#parse_subdomain' do
    it 'returns the host of the default url options' do
      original = Rails.application.routes.default_url_options.dup
      Rails.application.routes.default_url_options[:host] = 'https://lab.example.com:3000'

      expect(helper.parse_subdomain).to eq 'lab.example.com'
    ensure
      Rails.application.routes.default_url_options.replace(original)
    end
  end

  describe '#filter_steps_for_report' do
    let(:protocol) { my_module.protocol }
    let!(:completed) { create :step, protocol: protocol, user: user, completed: true }
    let!(:uncompleted) { create :step, protocol: protocol, user: user, completed: false }
    let!(:skipped) { create :step, protocol: protocol, user: user, completed: false, skipped_at: Time.current }

    def filter(flags)
      settings = { 'task' => { 'protocol' => flags } }
      helper.filter_steps_for_report(protocol.steps, settings)
    end

    it 'returns no steps when nothing is selected' do
      expect(filter({})).to be_empty
    end

    it 'returns only completed steps' do
      expect(filter('completed_steps' => true)).to contain_exactly(completed)
    end

    it 'returns only uncompleted steps that were not skipped' do
      expect(filter('uncompleted_steps' => true)).to contain_exactly(uncompleted)
    end

    it 'returns only skipped steps' do
      expect(filter('skipped_steps' => true)).to contain_exactly(skipped)
    end

    it 'combines the selected groups' do
      expect(filter('completed_steps' => true, 'skipped_steps' => true)).to contain_exactly(completed, skipped)
    end
  end

  describe '#order_results_for_report' do
    let!(:b_result) { create :result, my_module: my_module, user: user, name: 'B', created_at: 2.days.ago, updated_at: 1.day.ago }
    let!(:a_result) { create :result, my_module: my_module, user: user, name: 'A', created_at: 1.day.ago, updated_at: 3.days.ago }
    let!(:c_result) { create :result, my_module: my_module, user: user, name: 'C', created_at: 3.days.ago, updated_at: 2.days.ago }

    def ordered(order)
      helper.order_results_for_report(my_module.results, order).to_a
    end

    it 'orders by name ascending' do
      expect(ordered('atoz')).to eq [a_result, b_result, c_result]
    end

    it 'orders by name descending' do
      expect(ordered('ztoa')).to eq [c_result, b_result, a_result]
    end

    it 'orders by newest creation first' do
      expect(ordered('new')).to eq [a_result, b_result, c_result]
    end

    it 'orders by oldest update first' do
      expect(ordered('old_updated')).to eq [a_result, c_result, b_result]
    end

    it 'orders by newest update first' do
      expect(ordered('new_updated')).to eq [b_result, c_result, a_result]
    end

    it 'orders by oldest creation first by default' do
      expect(ordered(nil)).to eq [c_result, b_result, a_result]
    end

    it 'puts pinned results first in pin order' do
      b_result.update_columns(pinned_at: 1.hour.ago)
      a_result.update_columns(pinned_at: 2.hours.ago)

      expect(ordered('atoz').first(2)).to eq [a_result, b_result]
    end
  end

  describe '#report_experiment_descriptions' do
    it 'returns the descriptions of the experiments in the report' do
      ReportElement.create!(report: report, type_of: :experiment, position: 1, experiment: experiment)
      ReportElement.create!(report: report, type_of: :project_header, position: 2, project: project)

      expect(helper.report_experiment_descriptions(report)).to eq ['Experiment description']
    end
  end

  describe '#permit_report_settings_structure' do
    let(:repository) { create :repository, team: team, created_by: user }

    it 'keeps scalar keys, nests hashes and turns arrays into array permits' do
      definition = { exclude_timestamps: true, task: { protocol: { completed_steps: true } }, ids: [] }

      expect(helper.permit_report_settings_structure(definition, []))
        .to eq [:exclude_timestamps, { task: [{ protocol: [:completed_steps] }] }, { ids: [] }]
    end

    it 'permits excluded columns per repository id' do
      definition = { excluded_repository_columns: {} }

      expect(helper.permit_report_settings_structure(definition, [repository]))
        .to eq [{ excluded_repository_columns: { repository.id.to_s => [] } }]
    end

    it 'treats excluded columns as a plain hash without repositories' do
      expect(helper.permit_report_settings_structure({ excluded_repository_columns: { a: true } }, []))
        .to eq [{ excluded_repository_columns: [:a] }]
    end
  end

  describe '#custom_templates' do
    it 'is false with only the default template' do
      expect(helper.custom_templates({ scinote_template: 'x' })).to be false
    end

    it 'is true when another template exists' do
      expect(helper.custom_templates({ scinote_template: 'x', other: 'y' })).to be true
    end
  end

  describe '#report_form_response_content' do
    let(:form) { create :form, created_by: user, team: team }
    let(:form_response) do
      create :form_response, form: form, created_by: user, parent: create(:step, protocol: my_module.protocol, user: user)
    end

    def add_field(type, name, data = {})
      create :form_field, form: form, name: name, created_by: user, last_modified_by: user,
                          data: { type: type, validations: {} }.merge(data)
    end

    def add_value(klass, field, attrs = {})
      klass.create!({ form_response: form_response, form_field: field, created_by: user,
                      submitted_by: user, latest: true }.merge(attrs))
    end

    it 'formats the text value with its metadata' do
      field = add_field('FormTextFieldValue', 'Text field')
      submitted = Time.zone.parse('2026-05-04 09:15')
      add_value(FormTextFieldValue, field, text: 'plain text', submitted_at: submitted)

      expect(helper.report_form_response_content(form_response)).to eq [
        { name: 'Text field', value: 'plain text', submitted_at: I18n.l(submitted, format: :full),
          submitted_by: user.full_name }
      ]
    end

    it 'reports not applicable values' do
      field = add_field('FormTextFieldValue', 'Skipped field')
      add_value(FormTextFieldValue, field, not_applicable: true)

      expect(helper.report_form_response_content(form_response).first[:value])
        .to eq I18n.t('forms.export.values.not_applicable')
    end

    it 'localizes date values' do
      field = add_field('FormDatetimeFieldValue', 'Date field', time: false)
      add_value(FormDatetimeFieldValue, field, date: Date.new(2026, 5, 4))

      expect(helper.report_form_response_content(form_response).first[:value])
        .to eq I18n.l(Date.new(2026, 5, 4), format: :full_date)
    end

    it 'formats repository row values through the repository formatter' do
      field = add_field('FormRepositoryRowsFieldValue', 'Rows field')
      value = add_value(FormRepositoryRowsFieldValue, field, data: [{ 'id' => 7, 'name' => 'Row', 'repository_id' => nil, 'repository_cells' => [] }])

      expect(helper.report_form_response_content(form_response).first[:value])
        .to eq helper.form_repository_rows_field_value_formatter(value)
      expect(helper.report_form_response_content(form_response).first[:value])
        .to eq "Row (#{RepositoryRow::ID_PREFIX}7)"
    end

    it 'uses the formatted value of other value types' do
      field = add_field('FormNumberFieldValue', 'Number field')
      add_value(FormNumberFieldValue, field, number: 5)

      # number plus (blank) unit, as produced by FormNumberFieldValue#formatted
      expect(helper.report_form_response_content(form_response).first[:value]).to eq '5 '
    end

    it 'returns blank metadata for fields without a value' do
      add_field('FormTextFieldValue', 'Empty field')

      expect(helper.report_form_response_content(form_response))
        .to eq [{ name: 'Empty field', value: nil, submitted_at: '', submitted_by: '' }]
    end
  end
end
