# frozen_string_literal: true

require 'rails_helper'

describe Experiments::GenerateReportJob, type: :job do
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
  let(:analytical_report) do
    AnalyticalReport.create!(
      name: 'Experiment report', generating_status: :in_progress, reference: experiment,
      created_by: user, params: { 'my_module_ids' => [my_module.id] }
    )
  end
  let(:service) { instance_double(ExperimentReports::GenerateReportService, call: true) }

  before do
    MyModuleStatusFlow.ensure_default
    user.update!(current_team_id: team.id)
  end

  def run_job
    described_class.perform_now(analytical_report.id)
  end

  describe '#perform' do
    context 'with the service stubbed' do
      before { allow(ExperimentReports::GenerateReportService).to receive(:new).and_return(service) }

      it 'runs the service for the experiment and marks the report done' do
        run_job

        expect(ExperimentReports::GenerateReportService).to have_received(:new)
          .with(experiment, analytical_report, user)
        expect(service).to have_received(:call)
        expect(analytical_report.reload).to be_done
      end

      it 'logs the experiment analytical report generated activity' do
        expect { run_job }.to change { Activity.where(type_of: :experiment_analytical_report_generated).count }.by(1)

        activity = Activity.where(type_of: :experiment_analytical_report_generated).last
        expect(activity.owner).to eq user
        expect(activity.subject).to eq experiment
        expect(activity.team_id).to eq team.id
        expect(activity.project_id).to eq project.id
        expect(activity.message_items).to include(
          'analytical_report' => hash_including('id' => analytical_report.id),
          'experiment' => hash_including('id' => experiment.id)
        )
      end

      it 'destroys the analytical report and re-raises when the service fails' do
        allow(service).to receive(:call).and_raise(StandardError, 'merge failed')
        analytical_report

        expect { run_job }.to raise_error(StandardError, 'merge failed')
          .and change(AnalyticalReport, :count).by(-1)
        expect(Activity.where(type_of: :experiment_analytical_report_generated)).to be_empty
      end

      it 'raises RecordNotFound for an unknown report' do
        expect { described_class.perform_now(-1) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with the real service' do
      def attach_task_report(task, content)
        report = AnalyticalReport.create!(
          name: 'Task report', generating_status: :done, reference: task, created_by: user
        )
        report.report.attach(io: StringIO.new(content), filename: "task_#{task.id}.pdf")
        report
      end

      it 'attaches the only available task report as the experiment report' do
        attach_task_report(my_module, '%PDF task report')

        run_job

        analytical_report.reload
        expect(analytical_report).to be_done
        expect(analytical_report.report).to be_attached
        expect(analytical_report.report.filename.to_s).to eq 'Experiment report.pdf'
        expect(analytical_report.report.download).to eq '%PDF task report'
      end

      it 'merges the reports of several tasks in the requested order with pdfunite' do
        second_module = create :my_module, experiment: experiment, created_by: user,
                                           my_module_status: MyModuleStatus.first
        attach_task_report(my_module, '%PDF one')
        attach_task_report(second_module, '%PDF two')
        analytical_report.update!(params: { 'my_module_ids' => [second_module.id, my_module.id] })
        downloaded = []
        allow(Open3).to receive(:capture3) do |*args|
          downloaded << args[1..-2].map { |path| File.binread(path) }
          File.binwrite(args.last, '%PDF merged')
          ['', '', instance_double(Process::Status, success?: true)]
        end

        run_job

        expect(downloaded).to eq [['%PDF two', '%PDF one']]
        expect(analytical_report.reload.report.download).to eq '%PDF merged'
      end

      it 'keeps the first report when pdfunite cannot merge encrypted files' do
        second_module = create :my_module, experiment: experiment, created_by: user,
                                           my_module_status: MyModuleStatus.first
        attach_task_report(my_module, '%PDF one')
        attach_task_report(second_module, '%PDF two')
        analytical_report.update!(params: { 'my_module_ids' => [my_module.id, second_module.id] })
        allow(Open3).to receive(:capture3).and_return(
          ['', ExperimentReports::GenerateReportService::PDFUNITE_ENCRYPTED_PDF_ERROR_STRING,
           instance_double(Process::Status, success?: false)]
        )

        run_job

        expect(analytical_report.reload.report.download).to eq '%PDF one'
      end

      it 'fails when pdfunite fails for another reason' do
        second_module = create :my_module, experiment: experiment, created_by: user,
                                           my_module_status: MyModuleStatus.first
        attach_task_report(my_module, '%PDF one')
        attach_task_report(second_module, '%PDF two')
        analytical_report.update!(params: { 'my_module_ids' => [my_module.id, second_module.id] })
        allow(Open3).to receive(:capture3).and_return(['', 'boom', instance_double(Process::Status, success?: false)])

        expect { run_job }.to raise_error(StandardError, /error merging report and PDF file preview \(boom\)/)
          .and change(AnalyticalReport, :count).by(-1)
      end

      it 'reports a missing pdfunite binary' do
        second_module = create :my_module, experiment: experiment, created_by: user,
                                           my_module_status: MyModuleStatus.first
        attach_task_report(my_module, '%PDF one')
        attach_task_report(second_module, '%PDF two')
        analytical_report.update!(params: { 'my_module_ids' => [my_module.id, second_module.id] })
        allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)

        expect { run_job }.to raise_error(StandardError, 'Required command not found: pdfunite')
      end

      it 'fails and removes the report when a task report has no file attached' do
        AnalyticalReport.create!(name: 'Empty', generating_status: :done, reference: my_module, created_by: user)
        analytical_report

        expect { run_job }.to raise_error(StandardError, /has no file attached/)
          .and change { AnalyticalReport.where(reference: experiment).count }.by(-1)
      end

      it 'fails and removes the report when no task has a generated report' do
        analytical_report

        expect { run_job }.to raise_error(StandardError, 'No analytical reports available for generation')
          .and change(AnalyticalReport, :count).by(-1)
      end
    end
  end
end
