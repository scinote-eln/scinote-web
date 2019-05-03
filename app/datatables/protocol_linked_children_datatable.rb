class ProtocolLinkedChildrenDatatable < CustomDatatable
  def_delegator :@view, :link_to
  def_delegator :@view, :protocols_my_module_path

  def initialize(view, protocol, user, controller)
    super(view)
    @protocol = protocol
    @user = user
    @controller = controller
  end

  def sortable_columns
    @sortable_columns ||= [
      'Protocol.id'
    ]
  end

  def sortable_displayed_columns
    @sortable_displayed_columns ||= [
      '0'
    ]
  end

  def searchable_columns
    @searchable_columns ||= []
  end

  private

  # Returns json of current linked children (already paginated)
  def data
    records.map do |record|
      {
        'DT_RowId' => record.id,
        '1' => record_html(record)
      }
    end
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    records =
      Protocol
      .joins(my_module: { experiment: :project })
      .includes(my_module: { experiment: :project })
      .references(my_module: { experiment: :project })
      .where(protocol_type: Protocol.protocol_types[:linked])
      .where(parent: @protocol)
    records.distinct
  end

  # Helper methods

  def record_html(record)
    res = ''
    res += "<ol class='breadcrumb'>"
    res += "<li><span class='fas fa-folder'></span>&nbsp;"
    res += @controller.render_to_string(
      partial: 'search/results/partials/project_text.html.erb',
      locals: { project: record.my_module.experiment.project }
    )
    res += '</li>'
    res += "<li><i class='fas fa-flask'></i>&nbsp;"
    res += @controller.render_to_string(
      partial: 'search/results/partials/experiment_text.html.erb',
      locals: { experiment: record.my_module.experiment }
    )
    res += '</li>'
    res += "<li><span class='fas fa-credit-card'></span>&nbsp;"
    res += @controller.render_to_string(
      partial: 'search/results/partials/my_module_text.html.erb',
      locals: { my_module: record.my_module, link_to_page: :protocols }
    )
    res += '</li>'
    res += '</ol>'
    res
  end
end
