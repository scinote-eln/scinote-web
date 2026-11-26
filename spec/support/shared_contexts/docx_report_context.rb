# frozen_string_literal: true

require 'zip'

# Builds a real report (project > experiment > task) and a real Reports::Docx renderer that draws into a real
# Caracal document. Specs draw with the renderer (`renderer.draw_step(step)`, ...) and then read the generated
# document through `paragraph_texts`, `document_xml` or `document_node`.
#
# Override `report_settings` (a hash that is deep merged into Report::DEFAULT_SETTINGS) per context.
RSpec.shared_context 'docx_report' do
  let(:report_settings) { {} }

  let!(:user) { create :user, full_name: 'Report Author' }
  let!(:team) { create :team, created_by: user, skip_user_assignments: true }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create :user_assignment, user: user, assignable: team, user_role: owner_role }
  let!(:project) do
    create :project, name: 'Docx project', team: team, created_by: user, default_public_user_role_id: owner_role.id
  end
  let!(:experiment) { create :experiment, name: 'Docx experiment', project: project, created_by: user }
  let!(:my_module) do
    MyModuleStatusFlow.ensure_default
    create :my_module, name: 'Docx task', experiment: experiment, created_by: user,
                       my_module_status: MyModuleStatus.first
  end

  let(:report) do
    new_report = create :report, user: user, project: project, team: team, skip_user_assignments: true
    merged = Report::DEFAULT_SETTINGS.deep_dup.deep_merge(report_settings.deep_symbolize_keys)
    new_report.update!(settings: merged)
    Report.find(new_report.id)
  end

  let(:docx_file) { Tempfile.new(['report_spec', '.docx']) }
  let(:caracal_document) { Caracal::Document.new(docx_file.path) }
  let(:renderer) do
    user.update!(current_team_id: team.id)
    instance = Reports::Docx.new(report, caracal_document, user: user, scinote_url: 'http://localhost:3000/')
    instance.send(:initial_document_load)
    instance
  end

  after do
    docx_file.close
    docx_file.unlink
  end

  def document_xml
    caracal_document.save
    Zip::File.open(docx_file.path) { |zip| zip.read('word/document.xml') }
  end

  # External targets of all hyperlinks of the document (read from the relationships part)
  def link_targets
    document_xml
    rels = Zip::File.open(docx_file.path) { |zip| zip.read('word/_rels/document.xml.rels') }
    Nokogiri::XML(rels).remove_namespaces!.xpath('//Relationship[@TargetMode="External"]').map { |r| r['Target'] }
  end

  def document_node
    Nokogiri::XML(document_xml).remove_namespaces!
  end

  # Text of every paragraph (also paragraphs inside list items and table cells), in document order
  def paragraph_texts
    document_node.xpath('//p').map { |p| p.xpath('.//t').map(&:text).join }
  end

  def all_text
    paragraph_texts.join("\n")
  end

  def heading_texts(level)
    document_node.xpath("//p[pPr/pStyle/@val='Heading#{level}']").map { |p| p.xpath('.//t').map(&:text).join }
  end

  def table_rows(table_index = 0)
    document_node.xpath('//tbl')[table_index].xpath('./tr').map do |tr|
      tr.xpath('./tc').map { |tc| tc.xpath('.//t').map(&:text).join }
    end
  end

  def add_step(attrs = {})
    create :step, { protocol: my_module.protocol, user: user }.merge(attrs)
  end

  def add_step_element(step, element, position = nil)
    orderable = element.is_a?(Table) ? element.step_table : element
    create :step_orderable_element, step: step, orderable: orderable,
                                    position: position || step.step_orderable_elements.count
  end

  def add_result_element(result, orderable, position = nil)
    create :result_orderable_element, result: result, orderable: orderable,
                                      position: position || result.result_orderable_elements.count
  end

  # Replaces the stubbed-out network image step: a tiny preview double backed by the real fixture image
  def stub_image_preview(asset)
    preview = double('preview', processed: double('processed', url: 'http://localhost:3000/preview.jpg?a=1&b=2'),
                                blob: asset.file.blob)
    allow(Reports::Utils).to receive(:image_prepare).with(asset).and_return(preview)
    allow(FastImage).to receive(:size).and_return([600, 400])
  end
end
