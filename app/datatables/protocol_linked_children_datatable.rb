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
    if params[:version].present?
      records = @protocol.published_versions_with_original
                         .find_by!(version_number: params[:version])
                         .linked_children
    else
      records = Protocol.where(protocol_type: Protocol.protocol_types[:linked])
      records = records.where(parent_id: @protocol.published_versions)
                       .or(records.where(parent_id: @protocol.id))
    end
    records.preload(my_module: { experiment: :project }).distinct
  end

  # Helper methods

  def record_html(record)
    res = ''
    res += "<ol class='breadcrumb'>"
    res += "<li><span class='sn-icon sn-icon-projects'></span>&nbsp;"
    res += @controller.render_to_string(
      partial: 'search/results/partials/project_text',
      locals: { project: record.my_module.experiment.project, link_to_page: :show },
      formats: :html
    )
    res += '</li>'
    res += "<li><i class='sn-icon sn-icon-experiment'></i>&nbsp;"
    res += @controller.render_to_string(
      partial: 'search/results/partials/experiment_text',
      locals: { experiment: record.my_module.experiment },
      formats: :html
    )
    res += '</li>'
    res += "<li><span class='sn-icon sn-icon-task'></span>&nbsp;"
    res += @controller.render_to_string(
      partial: 'search/results/partials/my_module_text',
      locals: { my_module: record.my_module, link_to_page: :protocols },
      formats: :html
    )
    res += '</li>'
    res += '</ol>'
    res
  end
end
