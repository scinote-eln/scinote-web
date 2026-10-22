# frozen_string_literal: true

require 'rails_helper'

describe MyModules::GenerateReportJob, type: :job do
  let(:user) { create(:user).tap(&:confirm) }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:project) do
    create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id
  end
  let!(:project_assignment) { create_user_assignment(project, owner_role, user) }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, my_module_status: MyModuleStatus.first
  end
  let(:report_template) { ReportTemplate.create!(subject: my_module, name: 'Template') }
  let(:params) { {} }
  let(:analytical_report) do
    AnalyticalReport.create!(
      name: 'Analytical', generating_status: :in_progress, reference: my_module,
      created_by: user, report_template: report_template, params: params
    )
  end
  let(:generate_service) { instance_double(MyModuleReports::GenerateReportService, call: true) }
  let(:preview_service) { instance_double(PdfPreviewService, generate!: true) }
  let(:merge_service) { instance_double(MyModuleReports::MergePdfsWithWatermarkService, generate!: true) }

  before do
    MyModuleStatusFlow.ensure_default
    allow(MyModuleReports::GenerateReportService).to receive(:new).and_return(generate_service)
    allow(PdfPreviewService).to receive(:new).and_return(preview_service)
    allow(MyModuleReports::MergePdfsWithWatermarkService).to receive(:new).and_return(merge_service)
  end

  def run_job
    described_class.perform_now(analytical_report.id, team_id: team.id)
  end

  describe '#perform' do
    it 'generates the report from the task protocol and template, previews it and marks it done' do
      run_job

      expect(MyModuleReports::GenerateReportService).to have_received(:new)
        .with(my_module.protocol, report_template, team, user)
      expect(generate_service).to have_received(:call).with(analytical_report)
      expect(PdfPreviewService).to have_received(:new)
        .with(an_instance_of(ActiveStorage::Attached::One), an_instance_of(ActiveStorage::Attached::One))
      expect(preview_service).to have_received(:generate!)
      expect(analytical_report.reload).to be_done
    end

    it 'does not merge any assets when no asset groups were requested' do
      run_job

      expect(MyModuleReports::MergePdfsWithWatermarkService).not_to have_received(:new)
    end

    context 'with asset groups to append' do
      let(:params) do
        { 'asset_groups' => [{ 'type' => 'step', 'id' => 1, 'asset_ids' => [1, 2] }], 'header' => 'Head' }
      end

      it 'merges the assets with watermark using the report params' do
        run_job

        expect(MyModuleReports::MergePdfsWithWatermarkService).to have_received(:new).with(user, analytical_report)
        expect(merge_service).to have_received(:generate!)
        expect(analytical_report.reload).to be_done
      end
    end

    it 'logs the analytical report generated activity on the task' do
      expect { run_job }.to change { Activity.where(type_of: :task_analytical_report_generated).count }.by(1)

      activity = Activity.where(type_of: :task_analytical_report_generated).last
      expect(activity.owner).to eq user
      expect(activity.subject).to eq my_module
      expect(activity.team_id).to eq team.id
      expect(activity.project_id).to eq project.id
      expect(activity.message_items).to include(
        'analytical_report' => hash_including('id' => analytical_report.id),
        'report_template' => hash_including('id' => report_template.id),
        'my_module' => hash_including('id' => my_module.id)
      )
    end

    it 'uses the user date format only during generation' do
      user.settings[:date_format] = 'dd/mm/yyyy'
      user.save!
      seen = nil
      allow(generate_service).to receive(:call) { seen = I18n.backend.date_format }

      run_job

      expect(seen).to eq 'dd/mm/yyyy'
      expect(I18n.backend.date_format).to eq Constants::DEFAULT_DATE_FORMAT
    end

    context 'when generation fails' do
      before { allow(generate_service).to receive(:call).and_raise(StandardError, 'template broken') }

      it 'destroys the analytical report and re-raises' do
        analytical_report

        expect { run_job }.to raise_error(StandardError, 'template broken')
          .and change(AnalyticalReport, :count).by(-1)

        expect(AnalyticalReport.find_by(id: analytical_report.id)).to be_nil
        expect(I18n.backend.date_format).to eq Constants::DEFAULT_DATE_FORMAT
      end

      it 'does not log an activity' do
        expect { run_job rescue nil }.not_to(change { Activity.where(type_of: :task_analytical_report_generated).count })
      end
    end

    it 'destroys the report and re-raises when the preview fails' do
      allow(preview_service).to receive(:generate!).and_raise(StandardError, 'no preview')
      analytical_report

      expect { run_job }.to raise_error(StandardError, 'no preview')
        .and change(AnalyticalReport, :count).by(-1)
    end
  end
end
