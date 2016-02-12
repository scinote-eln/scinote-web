class SampleDatatable < AjaxDatatablesRails::Base
  include SamplesHelper

  ASSIGNED_SORT_COL = "assigned"

  def initialize(view, organization, project = nil, my_module = nil)
    super(view)
    @organization = organization
    @project = project
    @my_module = my_module
  end

  # Define sortable columns, so 1st column will be sorted by attribute in sortable_columns[0]
  def sortable_columns
    sort_array = [
      ASSIGNED_SORT_COL,
      "Sample.name",
      "SampleType.name",
      "SampleGroup.name",
      "Sample.created_at",
      "User.full_name",
    ]
    sort_array.push(*custom_fields_sort_by)

    @sortable_columns ||= sort_array
  end

  # Define attributes on which we perform search
  def searchable_columns
    search_array = [
      "Sample.name",
      "Sample.created_at",
      "SampleType.name",
      "SampleGroup.name",
      "Sample.created_at",
      "User.full_name"
    ]
    search_array.push(*custom_fields_sort_by)

    @searchable_columns ||= search_array
  end

  private

  # Get array of columns to sort by (for custom fields)
  def custom_fields_sort_by
    num_cf = CustomField.where(organization_id: @organization).count
    array = []

    for _ in 0..num_cf
      array << "SampleCustomField.value"
    end
    array
  end

  # Returns json of current samples (already paginated)
  def data
    records.map do |record|
      sample = {
        "DT_RowId": record.id,
        "1": assigned_cell(record),
        "2": record.name,
        "3": record.sample_type.nil? ? I18n.t("samples.table.no_type") : record.sample_type.name,
        "4": record.sample_group.nil? ?
        "<span class='glyphicon glyphicon-asterisk'></span> " + I18n.t("samples.table.no_group") :
        "<span class='glyphicon glyphicon-asterisk' style='color: #{record.sample_group.color}'></span> " + record.sample_group.name,
        "5": I18n.l(record.created_at, format: :full),
          "6": record.user.full_name,
          "sampleInfoUrl": Rails.application.routes.url_helpers.edit_sample_path(record.id),
          "sampleUpdateUrl": Rails.application.routes.url_helpers.sample_path(record.id)
      }

      # Add custom attributes
      record.sample_custom_fields.each do |scf|
        sample[@cf_mappings[scf.custom_field_id]] = scf.value
      end
      sample
    end
  end

  def assigned_cell(record)
    @assigned_samples.include?(record) ?
      "<span class='circle'>&nbsp;</span>" :
      "<span class='circle disabled'>&nbsp;</span>"
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    samples = Sample
    .includes(
      :sample_type,
      :sample_group,
      :user,
      :sample_custom_fields
    )
    .references(
      :sample_type,
      :sample_group,
      :user,
      :sample_custom_fields
    )
    .where(
      organization: @organization
    )

    if @my_module
      @assigned_samples = @my_module.samples
      samples = samples
      .joins(
        "LEFT OUTER JOIN sample_my_modules ON
        (samples.id = sample_my_modules.sample_id AND
          (sample_my_modules.my_module_id = #{@my_module.id.to_s} OR
          sample_my_modules.id IS NULL))"
      )
      .references(:sample_my_modules)
    elsif @project
      @assigned_samples = @project.assigned_samples
      ids = @project.my_modules.select(:id)
      samples = samples
      .joins(
        "LEFT OUTER JOIN sample_my_modules ON
        (samples.id = sample_my_modules.sample_id AND
          (sample_my_modules.my_module_id IN (#{ids.to_sql}) OR
          sample_my_modules.id IS NULL))"
      )
      .references(:sample_my_modules)
    end

    # Make mappings of custom fields, so we have same id for every column
    i = 7
    @cf_mappings = {}
    all_custom_fields.each do |cf|
      @cf_mappings[cf.id] = i.to_s
      i += 1
    end

    samples
  end

  # Override default behaviour
  # Don't filter and paginate records when sorting by custom column - everything
  # is done in sort_records method - you might ask why, well if you want the
  # number of samples/all samples it's dependant upon sort_record query
  def fetch_records
    records = get_raw_records
    records = sort_records(records) if params[:order].present?
    records = filter_records(records) if params[:search].present? && (not (sorting_by_custom_column))
    records = paginate_records(records) if (not (params[:length].present? && params[:length] == '-1')) && (not (sorting_by_custom_column))
    records
  end

  # Override default sort method if needed
  def sort_records(records)
    if params[:order].present? and params[:order].length == 1
      if sort_column(params[:order].values[0]) == ASSIGNED_SORT_COL
        # If "assigned" column is sorted
        if @my_module then
          # Depending on the sort, order nulls first or
          # nulls last on sample_my_modules association
          records.order("sample_my_modules.id NULLS #{sort_null_direction(params[:order].values[0])}")
        elsif @project
          # For project, simply sort on the count of assigned modules;
          # if sample is assigned to 0 modules, it's not assigned to project;
          # if it's assigned to > 0 modules, it's definately assigned to the
          # @project since we filtered the samples table to only include
          # the ones on this project
          records.order("samples.nr_of_modules_assigned_to #{inverse_sort_direction(params[:order].values[0])}")
        end
      elsif sorting_by_custom_column
        # Check if have to filter samples first
        if params[:search].present? and params[:search][:value].present?
          # Couldn't force ActiveRecord to yield the same query as below because
          # Rails apparently forgets to join stuff in subqueries -
          # #justrailsthings
          conditions = build_conditions_for(params[:search][:value])
          filter_query = 'SELECT "samples"."id" FROM "samples"
          LEFT OUTER JOIN "sample_custom_fields" ON "sample_custom_fields"."sample_id" = "samples"."id"
          LEFT OUTER JOIN "sample_types" ON "sample_types"."id" = "samples"."sample_type_id"
          LEFT OUTER JOIN "sample_groups" ON "sample_groups"."id" = "samples"."sample_group_id"
          LEFT OUTER JOIN "users" ON "users"."id" = "samples"."user_id"
          WHERE "samples"."organization_id" = ' + @organization.id.to_s + ' AND ' + conditions.to_sql

          records = records.where("samples.id IN (#{filter_query})")
        end

        cf_id = all_custom_fields[params[:order].values[0]["column"].to_i - 7].id
        dir = sort_direction(params[:order].values[0])

        # Because samples can have multiple sample custom fields, we first group
        # them by samples.id and inside that group we sort them by cf_id. Because
        # we sort them ASC, sorted columns will be on top. Distinct then only
        # takes the first row and cuts the rest of every group and voila we have
        # 1 row for every sample, which are not sorted yet ...
        records = records.select("DISTINCT ON (samples.id) *")
        .order("samples.id, CASE WHEN sample_custom_fields.custom_field_id = #{cf_id} THEN 1 ELSE 2 END ASC")

        # ... this little gem (pun intended) then takes the records query, sorts it again
        # and paginates it. sq.t0_* are determined empirically and are crucial -
        # imagine A -> B -> C transitive relation but where A and C are the
        # same. Useless right? But not when you acknowledge that find_by_sql
        # method does some funky stuff when your query spans multiple queries -
        # Sample object might have id from SampleType, name from
        # User ... chaos ensues basically. If something changes in db this might
        # change.
        Sample.find_by_sql("SELECT sq.t0_r0 as id, sq.t0_r1 as name, sq.t0_r4 as created_at, sq.t0_r5, sq.t0_r2 as user_id, sq.custom_field_id FROM (#{records.to_sql})
                                     as sq ORDER BY CASE WHEN sq.custom_field_id = #{cf_id} THEN 1 ELSE 2 END #{dir}, sq.value #{dir}
                                     LIMIT #{per_page} OFFSET #{offset}")
      else
        super(records)
      end
    else
      super(records)
    end
  end

  def sort_null_direction(item)
    val = sort_direction(item)
    val == "ASC" ? "LAST" : "FIRST"
  end

  def inverse_sort_direction(item)
    val = sort_direction(item)
    val == "ASC" ? "DESC" : "ASC"
  end

  def sorting_by_custom_column
    params[:order].values[0]["column"].to_i > 6
  end

end