# frozen_string_literal: true

require 'rails_helper'

# ActiveStorage::CheckBlobPermissions is exercised through ActiveStorage::Blobs::RedirectController,
# which includes it as a before_action.
describe ActiveStorage::Blobs::RedirectController, type: :controller do
  login_user

  include_context 'reference_project_structure', { step: true }

  # A task in a team the current user is not a member of.
  let(:foreign_my_module) { create :my_module }

  def new_blob(filename: 'file.txt', content_type: 'text/plain', content: 'content')
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new(content), filename: filename, content_type: content_type,
                                           metadata: { identified: true, analyzed: true })
  end

  def attach_blob(record, name)
    blob = new_blob
    record.public_send(name).attach(blob)
    blob
  end

  def asset_blob(asset)
    blob = new_blob
    asset.file.attach(blob)
    blob
  end

  def request_blob(blob)
    get :show, params: { signed_id: blob.signed_id, filename: blob.filename.to_s }
  end

  before do
    user.update!(current_team_id: team.id)
  end

  it 'returns 404 for a blob without attachments' do
    request_blob(new_blob)

    expect(response).to have_http_status(:not_found)
  end

  it 'returns 403 when the attachment record no longer exists' do
    asset = create :asset, team: team
    blob = asset_blob(asset)
    Asset.where(id: asset.id).delete_all

    request_blob(blob)

    expect(response).to have_http_status(:forbidden)
  end

  it 'returns 403 for an attachment on a record type without a permission rule' do
    blob = new_blob
    ActiveStorage::Attachment.create!(name: 'logo', record: team, blob: blob)

    request_blob(blob)

    expect(response).to have_http_status(:forbidden)
  end

  it 'grants access when any of several attachments is readable' do
    blob = new_blob
    create(:asset, team: team).file.attach(blob)
    create(:step_asset, step: step, asset: create(:asset, team: team)).asset.file.attach(blob)

    request_blob(blob)

    expect(response).to have_http_status(:redirect)
  end

  describe 'Asset attachments' do
    it 'redirects to the blob url for a file on a step of a readable task' do
      blob = asset_blob(create(:step_asset, step: step).asset)

      request_blob(blob)

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('/rails/active_storage/disk/')
    end

    it 'allows a file on a step of a readable repository protocol' do
      protocol = create :protocol, :in_repository_draft, team: team, added_by: user
      repository_step = create :step, protocol: protocol, user: user
      blob = asset_blob(create(:step_asset, step: repository_step).asset)

      request_blob(blob)

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids a file on a step of a task in another team' do
      foreign_step = create :step, protocol: foreign_my_module.protocol
      blob = asset_blob(create(:step_asset, step: foreign_step).asset)

      request_blob(blob)

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows a file on a result of a readable task' do
      result = create :result, my_module: my_module, user: user
      blob = asset_blob(create(:result_asset, result: result).asset)

      request_blob(blob)

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids a file on a result of a task in another team' do
      result = create :result, my_module: foreign_my_module
      blob = asset_blob(create(:result_asset, result: result).asset)

      request_blob(blob)

      expect(response).to have_http_status(:forbidden)
    end

    context 'with a file in an inventory cell' do
      def inventory_asset(repository)
        row = create :repository_row, repository: repository
        column = create :repository_column, :asset_type, repository: repository
        asset = create :asset, team: repository.team
        create :repository_asset_value, asset: asset,
                                        repository_cell_attributes: { repository_row: row, repository_column: column }
        asset
      end

      it 'allows it when the inventory is readable' do
        blob = asset_blob(inventory_asset(create(:repository, team: team, created_by: user)))

        request_blob(blob)

        expect(response).to have_http_status(:redirect)
      end

      it 'forbids it when the inventory belongs to another team' do
        blob = asset_blob(inventory_asset(create(:repository)))

        request_blob(blob)

        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'forbids a file that is not linked to a step, result or inventory cell' do
      blob = asset_blob(create(:asset, team: team))

      request_blob(blob)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'TinyMceAsset attachments' do
    def tiny_mce_blob(team:, object: nil)
      tiny_mce_asset = TinyMceAsset.create!(team: team, object: object)
      attach_blob(tiny_mce_asset, :image)
    end

    it 'allows an unassigned image of a team the user belongs to' do
      request_blob(tiny_mce_blob(team: team))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids an unassigned image of another team' do
      request_blob(tiny_mce_blob(team: create(:team)))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows an image in a readable task' do
      request_blob(tiny_mce_blob(team: team, object: my_module))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids an image in a task of another team' do
      request_blob(tiny_mce_blob(team: team, object: foreign_my_module))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows an image in a readable protocol' do
      request_blob(tiny_mce_blob(team: team, object: my_module.protocol))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids an image in a protocol of another team' do
      request_blob(tiny_mce_blob(team: team, object: foreign_my_module.protocol))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows an image in a readable result text' do
      result_text = create :result_text, result: create(:result, my_module: my_module, user: user)

      request_blob(tiny_mce_blob(team: team, object: result_text))

      expect(response).to have_http_status(:redirect)
    end

    it 'allows an image in a readable step text' do
      request_blob(tiny_mce_blob(team: team, object: create(:step_text, step: step)))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids an image in a step text of another team' do
      foreign_step = create :step, protocol: foreign_my_module.protocol

      request_blob(tiny_mce_blob(team: team, object: create(:step_text, step: foreign_step)))

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids an image on an unsupported object type' do
      request_blob(tiny_mce_blob(team: team, object: step))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'other attachment records' do
    it 'allows an experiment workflow image of a readable experiment' do
      request_blob(attach_blob(experiment, :workflowimg))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids an experiment workflow image of another team' do
      request_blob(attach_blob(foreign_my_module.experiment, :workflowimg))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows a storage location image of the current team' do
      location = StorageLocation.create!(name: 'Freezer', team: team, created_by: user)

      request_blob(attach_blob(location, :image))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids a storage location image of another team' do
      other_team = create :team
      location = StorageLocation.create!(name: 'Freezer', team: other_team, created_by: other_team.created_by)

      request_blob(attach_blob(location, :image))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows a report file of a readable project' do
      report = create :report, project: project, team: team, user: user

      request_blob(attach_blob(report, :pdf_file))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids a report file of a project in another team' do
      foreign_project = foreign_my_module.experiment.project
      report = create :report, project: foreign_project, team: foreign_project.team, user: foreign_project.created_by

      request_blob(attach_blob(report, :pdf_file))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows a report template of a readable protocol' do
      template = ReportTemplate.create!(name: 'Template', subject: my_module.protocol)

      request_blob(attach_blob(template, :odt_template_file))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids a report template of a protocol in another team' do
      template = ReportTemplate.create!(name: 'Template', subject: foreign_my_module.protocol)

      request_blob(attach_blob(template, :odt_template_file))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows an analytical report of a readable task' do
      report = AnalyticalReport.create!(name: 'Task report', reference: my_module)

      request_blob(attach_blob(report, :report))

      expect(response).to have_http_status(:redirect)
    end

    it 'allows an analytical report of a readable experiment' do
      report = AnalyticalReport.create!(name: 'Experiment report', reference: experiment)

      request_blob(attach_blob(report, :report))

      expect(response).to have_http_status(:redirect)
    end

    it 'forbids an analytical report of an experiment in another team' do
      report = AnalyticalReport.create!(name: 'Experiment report', reference: foreign_my_module.experiment)

      request_blob(attach_blob(report, :report))

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids an analytical report with an unsupported reference' do
      report = AnalyticalReport.create!(name: 'Project report', reference: project)

      request_blob(attach_blob(report, :report))

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows any user avatar' do
      request_blob(attach_blob(create(:user), :avatar))

      expect(response).to have_http_status(:redirect)
    end

    context 'with zip exports' do
      # ZipExport#self_destruct schedules deletion days later; with Delayed::Worker.delay_jobs = false
      # (spec default) it would delete the export right after creation.
      around do |example|
        delay_jobs = Delayed::Worker.delay_jobs
        Delayed::Worker.delay_jobs = true
        example.run
      ensure
        Delayed::Worker.delay_jobs = delay_jobs
      end

      it 'allows a zip export of the current user' do
        request_blob(attach_blob(create(:zip_export, user: user), :zip_file))

        expect(response).to have_http_status(:redirect)
      end

      it 'forbids a zip export of another user' do
        request_blob(attach_blob(create(:zip_export), :zip_file))

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with temp files' do
      # Controller specs do not put a session id into the session options, and `process` builds a new
      # TestRequest (resetting the options), so the instance cannot be prepared up front.
      before do
        allow_any_instance_of(ActionController::TestRequest).to receive(:session_options).and_return({ id: 'spec-session' })
      end

      it 'allows a temp file of the current session' do
        temp_file = create :temp_file, session_id: 'spec-session'

        request_blob(attach_blob(temp_file, :file))

        expect(response).to have_http_status(:redirect)
      end

      it 'forbids a temp file of another session' do
        temp_file = create :temp_file, session_id: 'another-session'

        request_blob(attach_blob(temp_file, :file))

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
