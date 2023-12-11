# frozen_string_literal: true

module Lists
  class BaseService
    def initialize(raw_data, params, user: nil)
      @raw_data = raw_data
      @params = params
      @user = user
      @filters = params[:filters] || {}
    end

    def call
      records = fetch_records
      records = filter_records(records)
      records = sort_records(records)
      paginate_records(records)
    end

    private

    def order_params
      @order_params ||= @params.require(:order).permit(:column, :dir).to_h
    end

    def paginate_records(records)
      records.page(@params[:page]).per(@params[:per_page])
    end

    def sort_direction(order_params)
      order_params[:dir] == 'asc' ? 'ASC' : 'DESC'
    end

    def sort_records(records)
      return records unless @params[:order]

      sort_by = "#{sortable_columns[order_params[:column].to_sym]} #{sort_direction(order_params)}"
      records.order(sort_by)
    end
  end
end
