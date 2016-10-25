class WidgetSamplesDatatable < AjaxDatatablesRails::Base
  include SamplesHelper

  def initialize(view,
                 organization,
                 my_module)
    super(view)
    @organization = organization
    @my_module = my_module
  end

  def sortable_columns
    sort_array = [
      'Sample.name',
      'SampleType.name',
      'SampleGroup.name',
      'Sample.created_at',
      'User.full_name'
    ]

    @sortable_columns ||= sort_array
  end

  private

  # Returns json of current samples
  def data
    records.map do |record|
      sample = {
        '0': record.name,
        '1': if record.sample_type.nil?
               I18n.t('samples.table.no_type')
             else
               record.sample_type.name
             end,
        '2': if record.sample_group.nil?
               "<span class='glyphicon glyphicon-asterisk'></span> " +
                 I18n.t('samples.table.no_group')
             else
               "<span class='glyphicon glyphicon-asterisk'
               style='color: #{record.sample_group.color}'></span> " +
                 record.sample_group.name
             end,
        '3': I18n.l(record.created_at, format: :full),
        '4': record.user.full_name
      }

      sample
    end
  end

  def get_raw_records
    @my_module.samples.joins(:user)
              .joins('LEFT OUTER JOIN sample_types ON
                samples.sample_type_id = sample_types.id')
              .joins('LEFT OUTER JOIN sample_groups ON
                samples.sample_group_id = sample_groups.id')
  end
end
