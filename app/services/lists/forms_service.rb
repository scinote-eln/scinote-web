# frozen_string_literal: true

module Lists
  class FormsService < BaseService
    def initialize(user, team, params)
      super(nil, params, user: user)
      @team = team
    end

    def fetch_records
      @records = Form.where(team: @team).readable_by_user(@user)

      view_mode = @params[:view_mode] || 'active'

      @records = @records.archived if view_mode == 'archived'
      @records = @records.active if view_mode == 'active'
    end

    def filter_records; end
  end
end
