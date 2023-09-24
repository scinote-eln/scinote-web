# frozen_string_literal: true

class CustomDatatableV2
  attr_reader :params, :options

  def initialize(view, raw_data, options = {})
    @raw_data = raw_data
    @params = view.params
    @options = options
  end

  def as_json(_options = {})
    {
      data: data,
      pageTotal: records.total_pages
    }
  end

  def records
    @records ||= fetch_records
  end

  private

  def order_params
    @order_params ||=
      params.require(:order).permit(:column, :dir).to_h
  end

  def fetch_records
    records = get_raw_records
    records = sort_records(records) if params[:order].present?
    records = paginate_records(records) if params[:page].present?
    records = filter_records(records) if params[:search].present?
    records
  end

  def paginate_records(records)
    records.page(params[:page]).per(params[:per_page])
  end

  def sort_direction(order_params)
    order_params[:dir] == 'asc' ? 'ASC' : 'DESC'
  end

  def sort_records(records)
    sort_by = "#{sortable_columns[order_params[:column].to_sym]} #{sort_direction(order_params)}"
    records.order(sort_by)
  end

  def generate_sortable_displayed_columns
    @sortable_displayed_columns = []
    columns_params.each_value do |col|
      @sortable_displayed_columns << col[:data] if col[:orderable] == 'true'
    end
    @sortable_displayed_columns
  end

  def formated_date
    f_date = I18n.backend.date_format.dup
    f_date.gsub!(/%-d/, 'FMDD')
    f_date.gsub!(/%d/, 'DD')
    f_date.gsub!(/%-m/, 'FMMM')
    f_date.gsub!(/%m/, 'MM')
    f_date.gsub!(/%b/, 'Mon')
    f_date.gsub!(/%B/, 'Month')
    f_date.gsub!('%Y', 'YYYY')
    f_date += ' HH24:MI'
    f_date
  end
end
