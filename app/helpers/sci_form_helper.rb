module SciFormHelper
  class SciFormBuilder < ActionView::Helpers::FormBuilder
    include SciFormHelper
    # Returns Bootstrap date-time picker of the "datetime" type tailored for accessing a specified datetime attribute (identified by +name+) on an object
    # assigned to the template (identified by +object+). Additional options on the input tag can be passed as a
    # hash with +options+. The supported options are shown in the following examples.
    #
    # ==== Examples
    #   Specify custom label (otherwise, a humanized version of +name+ is used)
    #   # => datetime_picker(:post, :published, label: "Published date")
    #
    #   Specify custom CSS style on the element
    #   # => datetime_picker(:post, :published, style: "background-color: #000; margin-top: 20px;")
    #
    #   Show a "clear" button on the bottom of the date picker.
    #   # => datetime_picker(:post, :published, clear: true)
    #
    #   Show a "today" button on the bottom of the date picker.
    #   # => datetime_picker(:post, :published, today: true)
    def datetime_picker(name, options = {})
      id = "#{@object_name}_#{name}"
      input_name = "#{@object_name}[#{name}]"
      value = options[:value] ? options[:value].strftime("#{I18n.backend.date_format} %H:%M") : ''
      js_locale = I18n.locale.to_s
      js_format = options[:time] ? datetime_picker_format_full : datetime_picker_format_date_only

      label = options[:label] || name.to_s.humanize

      style = options[:style] ? "style='#{options[:style]}'" : ''

      res = "<div class='form-group' #{style}><label class='control-label required' for='#{id}'>#{label}</label>" \
            "<div class='container' style='padding-left: 0; margin-left: 0;'><div class='row'><div class='col-sm-6'>"

      res << "<div class='input-group date'>" if options[:clear]

      res << "<input type='datetime' class='form-control' name='#{input_name}' id='#{id}' " \
             "readonly value='#{value}' data-toggle='date-time-picker' data-date-format='#{js_format}' " \
             "data-date-locale='#{js_locale}' data-date-show-today-button='#{options[:today].present?}'/>"

      if options[:clear]
        res << "<span class='input-group-addon' data-toggle='clear-date-time-picker' data-target='#{id}'>" \
               "<i class='sn-icon sn-icon-close'></i></span></div>"
      end

      res << '</div></div></div></div>'
      res.html_safe
    end

    # Returns smart <textarea> that dynamically resizes depending on the user
    # input. Also has an option 'single_line: true' to render it as a one-line
    # (imagine <input type="text">) input field that only grows beyond one line
    # if inputting a larger text (otherwise, by default it spans 2 lines).
    #
    # Other than that, it accepts same options as regular text_area helper.
    def smart_text_area(name, opts = {})
      opts[:class] = [opts[:class], 'smart-text-area'].join(' ')
      if !opts[:rows] && @object
        opts[:rows] =
          @object.public_send(name).try(:lines).try(:count)
      end
      opts.delete(:rows) if opts[:rows].nil?
      if opts[:single_line]
        opts[:class] = if opts[:rows]
                         [opts[:class], 'textarea-sm-present'].join(' ')
                       else
                         [opts[:class], 'textarea-sm'].join(' ')
                       end
      end
      text_area(name, opts)
    end

    # Returns <textarea> helper tag for tinyMCE editor
    def tiny_mce_editor(name, options = {})
      options.deep_merge!(cols: 120,
                          rows: 10,
                          data: {
                            tinymce_asset_path:
                              Rails.application.routes.url_helpers.tiny_mce_assets_path
                          })
      text_area(name, options)
    end
  end

  # Returns date only format string for Bootstrap DateTimePicker
  def datetime_picker_format_date_only
    js_format = I18n.backend.date_format.dup
    js_format.gsub!(/%-d/, 'D')
    js_format.gsub!(/%d/, 'DD')
    js_format.gsub!(/%-m/, 'M')
    js_format.gsub!(/%m/, 'MM')
    js_format.gsub!(/%b/, 'MMM')
    js_format.gsub!(/%B/, 'MMMM')
    js_format.gsub!('%Y', 'YYYY')
    js_format
  end

  def datetime_picker_format_date_only_vue
    js_format = I18n.backend.date_format.dup
    js_format.gsub!(/%-d/, 'd')
    js_format.gsub!(/%d/, 'dd')
    js_format.gsub!(/%-m/, 'M')
    js_format.gsub!(/%m/, 'MM')
    js_format.gsub!(/%b/, 'MMM')
    js_format.gsub!(/%B/, 'MMMM')
    js_format.gsub!('%Y', 'yyyy')
    js_format
  end

  # Returns date and time format string for Bootstrap DateTimePicker
  def datetime_picker_format_full
    js_format = datetime_picker_format_date_only
    js_format << ' HH:mm'
    js_format
  end

  def datetime_picker_format_full_vue
    js_format = datetime_picker_format_date_only_vue
    js_format << ' HH:mm'
    js_format
  end
end
