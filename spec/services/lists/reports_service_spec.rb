# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::ReportsService do
  let(:creator_a) { create :user, full_name: 'Zora Creator' }
  let(:creator_b) { create :user, full_name: 'Adam Creator' }
  let(:modifier) { create :user, full_name: 'Mona Modifier' }
  let(:team) { create :team, created_by: creator_a }
  let(:project_a) { create :project, team: team, created_by: creator_a, name: 'Proj Beta' }
  let(:project_b) { create :project, team: team, created_by: creator_a, name: 'Proj Alpha' }
  let!(:report_one) do
    create :report, user: creator_a, project: project_a, team: team, name: 'Report Charlie',
                    description: 'about cells', last_modified_by: modifier, created_at: 3.days.ago, updated_at: 1.day.ago
  end
  let!(:report_two) do
    create :report, user: creator_b, project: project_b, team: team, name: 'Report Alpha',
                    description: 'about mice', last_modified_by: nil, created_at: 2.days.ago, updated_at: 3.days.ago
  end
  let!(:report_three) do
    create :report, user: creator_a, project: project_b, team: team, name: 'Report Bravo',
                    description: 'about plants', last_modified_by: creator_a, created_at: 1.day.ago, updated_at: 2.days.ago
  end

  def call(extra = {})
    described_class.new(Report.where(team: team), ActionController::Parameters.new({ page: 1, per_page: 10 }.merge(extra))).call
  end

  def names(extra = {})
    call(extra).map(&:name)
  end

  it 'returns all reports with project, creator and modifier names' do
    records = call.index_by(&:name)
    expect(records.keys).to match_array(['Report Charlie', 'Report Alpha', 'Report Bravo'])
    expect(records['Report Charlie']).to have_attributes(project_name: 'Proj Beta', created_by_name: 'Zora Creator',
                                                         modified_by_name: 'Mona Modifier')
    expect(records['Report Alpha'].modified_by_name).to be_nil
  end

  it 'paginates' do
    expect(call(per_page: 2).size).to eq 2
    expect(call(per_page: 2, page: 2).size).to eq 1
  end

  describe 'search' do
    it 'matches the report name' do
      expect(names(search: 'Bravo')).to eq ['Report Bravo']
    end

    it 'matches the description' do
      expect(names(search: 'mice')).to eq ['Report Alpha']
    end

    it 'matches the prefixed id' do
      expect(names(search: "RP#{report_one.id}")).to include('Report Charlie')
    end

    it 'matches the project name' do
      expect(names(search: 'Beta')).to eq ['Report Charlie']
    end

    it 'matches the creator name' do
      expect(names(search: 'Adam')).to eq ['Report Alpha']
    end

    it 'matches the modifier name' do
      expect(names(search: 'Modifier')).to eq ['Report Charlie']
    end

    it 'ignores a blank search' do
      expect(names(search: '').size).to eq 3
    end
  end

  describe 'sorting' do
    def sorted(column, dir)
      names(order: { column: column, dir: dir })
    end

    it 'does not sort without order params' do
      expect(names).to match_array(Report.where(team: team).pluck(:name))
    end

    it 'sorts by name in both directions' do
      expect(sorted('name', 'asc')).to eq ['Report Alpha', 'Report Bravo', 'Report Charlie']
      expect(sorted('name', 'desc')).to eq ['Report Charlie', 'Report Bravo', 'Report Alpha']
    end

    it 'sorts by project name, then id' do
      expect(sorted('project_name', 'asc')).to eq ['Report Alpha', 'Report Bravo', 'Report Charlie']
    end

    it 'sorts by creator name' do
      expect(sorted('created_by_name', 'asc').first).to eq 'Report Alpha'
      expect(sorted('created_by_name', 'desc').last).to eq 'Report Alpha'
    end

    it 'sorts by modifier name' do
      expect(sorted('modified_by_name', 'asc').first(2)).to eq ['Report Charlie', 'Report Bravo']
    end

    it 'sorts by creation and update date' do
      expect(sorted('created_at', 'asc')).to eq ['Report Charlie', 'Report Alpha', 'Report Bravo']
      expect(sorted('updated_at', 'desc')).to eq ['Report Charlie', 'Report Bravo', 'Report Alpha']
    end

    it 'sorts by code (id)' do
      expect(sorted('code', 'asc')).to eq [report_one, report_two, report_three].sort_by(&:id).map(&:name)
      expect(sorted('code', 'desc')).to eq [report_one, report_two, report_three].sort_by(&:id).reverse.map(&:name)
    end

    %w(pdf_file docx_file).each do |column|
      context "by #{column} attachment" do
        before do
          # attached in this order, so the attachment ids are ordered Bravo < Alpha
          [report_three, report_two].each do |report|
            report.public_send(column).attach(io: StringIO.new('x'), filename: 'x.bin')
          end
        end

        it 'puts reports with an attachment before those without when ascending' do
          result = sorted(column, 'asc')
          expect(result.last).to eq 'Report Charlie'
          expect(result.first(2)).to match_array(['Report Alpha', 'Report Bravo'])
        end

        it 'puts reports without an attachment first when descending' do
          result = sorted(column, 'desc')
          expect(result.first).to eq 'Report Charlie'
          expect(result.last(2)).to match_array(['Report Alpha', 'Report Bravo'])
        end

        it 'orders the attached reports by attachment in opposite directions' do
          asc = sorted(column, 'asc').first(2)
          expect(sorted(column, 'desc').last(2)).to eq asc.reverse
        end
      end
    end
  end
end
