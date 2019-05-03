class CustomDatatable < AjaxDatatablesRails::Base
  private

  def dt_params
    @dt_params ||=
      params.permit(:assigned, :draw, :length, :start, search: %i(value regex))
            .to_h
  end

  def columns_params
    @columns_params ||= params.require(:columns).permit!.to_h
  end

  def order_params
    @order_params ||=
      params.require(:order).require('0').permit(:column, :dir).to_h
  end

  def fetch_records
    records = get_raw_records
    records = sort_records(records) if order_params.present?
    records = filter_records(records) if dt_params[:search].present?
    records = paginate_records(records) unless dt_params[:length].present? &&
                                               dt_params[:length] == '-1'
    records
  end

  def sort_records(records)
    sort_by = "#{sort_column(order_params)} #{sort_direction(order_params)}"
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
