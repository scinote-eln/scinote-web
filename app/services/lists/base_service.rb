# frozen_string_literal: true

module Lists
  class BaseService
    def initialize(raw_data, params, user: nil)
      @raw_data = raw_data
      @params = params
      @user = user
      @filters = params[:filters] || {}
      @records = []
    end

    def call
      fetch_records
      filter_records
      sort_records
      paginate_records
      @records
    end

    private

    def fetch_records
      raise NotImplementedError
    end

    def order_params
      @order_params ||= @params.require(:order).permit(:column, :dir).to_h
    end

    def paginate_records
      @records = @records.page(@params[:page]).per(@params[:per_page])
    end

    def sort_direction(order_params)
      order_params[:dir] == 'asc' ? 'ASC' : 'DESC'
    end

    def sort_records
      return unless @params[:order]

      sort_by = "#{sortable_columns[order_params[:column].to_sym]} #{sort_direction(order_params)}"
      @records = @records.order(sort_by).order(:id)
    end
  end
end
