# frozen_string_literal: true

module Lists
  class FormsService < BaseService
    def initialize(user, team, params)
      super(nil, params, user: user)
      @team = team
    end

    def fetch_records
      @records = Form.where(team: @team)
    end

    def filter_records; end
  end
end
