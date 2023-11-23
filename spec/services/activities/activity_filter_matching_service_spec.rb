# frozen_string_literal: true

require 'rails_helper'

describe Activities::ActivityFilterMatchingService do
  let(:user) { create :user }
  let(:user_2) { create :user }
  let(:team) { create :team, created_by: user }
  let(:team_2) { create :team, created_by: user_2 }
  let(:project) do
    create :project, team: team, user_projects: []
  end
  let(:project_2) do
    create :project, team: team, user_projects: []
  end
  let(:activity) { create :activity }

  it 'matches activity filters by activity date' do
    matching_filter = ActivityFilter.create(
      name: "date filter",
      filter: {"to_date"=>"2021-1-1", "from_date"=>"2021-1-6"}
    )

    non_matching_filter = ActivityFilter.create(
      name: "date filter",
      filter: {"to_date"=>"2021-12-1", "from_date"=>"2021-12-2"}
    )

    activity.update_column(:created_at, Date.parse("2021-1-4").to_time)
    p activity
    matched_activity_filters = Activities::ActivityFilterMatchingService.new(activity).activity_filters

    expect(matched_activity_filters).to include(matching_filter)
    expect(matched_activity_filters).to_not include(non_matching_filter)
  end

  it 'matches activity filters by activity user' do
    matching_filter = ActivityFilter.create(
      name: "user filter 1",
      filter: {"users" => [user.id.to_s], "from_date" => "", "to_date" => ""}
    )

    non_matching_filter = ActivityFilter.create(
      name: "user filter 2",
      filter: {"users" => [user_2.id.to_s], "from_date" => "", "to_date" => ""}
    )

    activity.update_column(:owner_id, user.id)

    matched_activity_filters = Activities::ActivityFilterMatchingService.new(activity).activity_filters

    expect(matched_activity_filters).to include(matching_filter)
    expect(matched_activity_filters).to_not include(non_matching_filter)
  end

  it 'matches activity filters by activity type' do
    matching_filter = ActivityFilter.create(
      name: "type filter 1",
      filter: {"types" => ["163"], "from_date" => "", "to_date" => ""}
    )

    non_matching_filter = ActivityFilter.create(
      name: "type filter 2",
      filter: {"types" => ["0"], "from_date" => "", "to_date" => ""}
    )

    activity.update_column(:type_of, 163)

    matched_activity_filters = Activities::ActivityFilterMatchingService.new(activity).activity_filters

    expect(matched_activity_filters).to include(matching_filter)
    expect(matched_activity_filters).to_not include(non_matching_filter)
  end

  it 'matches activity filters by activity team' do
    matching_filter = ActivityFilter.create(
      name: "team filter 1",
      filter: {"teams" => [team.id.to_s], "from_date" => "", "to_date" => ""}
    )

    non_matching_filter = ActivityFilter.create(
      name: "team filter 2",
      filter: {"teams" => [team_2.id.to_s], "from_date" => "", "to_date" => ""}
    )

    activity.update_column(:team_id, team.id)

    matched_activity_filters = Activities::ActivityFilterMatchingService.new(activity).activity_filters

    expect(matched_activity_filters).to include(matching_filter)
    expect(matched_activity_filters).to_not include(non_matching_filter)
  end

  it 'matches activity filters by activity subject' do
    matching_filter = ActivityFilter.create(
      name: "subject filter 1",
      filter: {"subjects" => { "Project" => [project.id.to_s] }, "from_date" => "", "to_date" => ""}
    )

    non_matching_filter = ActivityFilter.create(
      name: "subject filter 2",
      filter: {"subjects" => { "Project" => [project_2.id.to_s] }, "from_date" => "", "to_date" => ""}
    )

    activity.update_columns(subject_type: "Project", subject_id: project.id)

    matched_activity_filters = Activities::ActivityFilterMatchingService.new(activity).activity_filters

    expect(matched_activity_filters).to include(matching_filter)
    expect(matched_activity_filters).to_not include(non_matching_filter)
  end

  it 'matches activity filters by a combination of filters' do
    matching_filter = ActivityFilter.create(
      name: "mixed filter 1",
      filter: {
        "subjects" => { "Project" => [project.id.to_s] },
        "to_date"=>"2021-1-1",
        "from_date"=>"2021-1-6",
        "teams"=>[team.id.to_s],
        "users"=>[user.id.to_s],
        "types"=>["163"]
      }
    )

    activity.update_columns(
      created_at: Date.parse("2021-1-4").to_time,
      owner_id: user.id,
      type_of: 163,
      subject_type: "Project",
      subject_id: project.id,
      team_id: team.id
    )

    non_matching_filter_1 = ActivityFilter.create(
      name: "mixed filter 1",
      filter: {
        "subjects" => { "Project" => [project.id.to_s] },
        "to_date"=>"2021-10-2",
        "from_date"=>"2021-10-1",
        "teams"=>[team.id.to_s],
        "users"=>[user.id.to_s],
        "types"=>["163"]
      }
    )

    non_matching_filter_2 = ActivityFilter.create(
      name: "mixed filter 2",
      filter: {
        "subjects" => { "Project" => [project.id.to_s] },
        "to_date"=>"2021-1-2",
        "from_date"=>"2021-1-1",
        "teams"=>[team_2.id.to_s],
        "users"=>[user.id.to_s],
        "types"=>["163"]
      }
    )

    non_matching_filter_3 = ActivityFilter.create(
      name: "mixed filter 3",
      filter: {
        "subjects" => { "Project" => [project_2.id.to_s] },
        "to_date"=>"2021-1-2",
        "from_date"=>"2021-1-1",
        "teams"=>[team.id.to_s],
        "users"=>[user.id.to_s],
        "types"=>["163"]
      }
    )

    matched_activity_filters = Activities::ActivityFilterMatchingService.new(activity).activity_filters

    expect(matched_activity_filters).to include(matching_filter)
    expect(matched_activity_filters).to_not include(non_matching_filter_1)
    expect(matched_activity_filters).to_not include(non_matching_filter_2)
    expect(matched_activity_filters).to_not include(non_matching_filter_3)
  end
end
