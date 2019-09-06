module BootstrapFormHelper

  # Extend Bootstrap form builder
  class BootstrapForm::FormBuilder

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
      id = "#{@object_name}_#{name.to_s}"
      input_name = "#{@object_name}[#{name.to_s}]"
      timestamp = @object[name] ? "#{@object[name].to_i}000" : ""
      js_locale = I18n.locale.to_s
      js_format = I18n.backend.date_format.dup
      js_format.gsub!(/%-d/, 'D')
      js_format.gsub!(/%d/, 'DD')
      js_format.gsub!(/%-m/, 'M')
      js_format.gsub!(/%m/, 'MM')
      js_format.gsub!(/%b/, 'MMM')
      js_format.gsub!(/%B/, 'MMMM')
      js_format.gsub!('%Y', 'YYYY')

      label = name.to_s.humanize
      if options[:label] then
        label = options[:label]
      end

      styleStr = ""
      if options[:style] then
        styleStr = "style='#{options[:style]}'"
      end

      jsOpts = ""
      if options[:today] then
        jsOpts << "showTodayButton: true, "
      end

      res = ""
      res << "<div class='form-group' #{styleStr}><label class='control-label required' for='#{id}'>#{label}</label><div class='container' style='padding-left: 0; margin-left: 0;'><div class='row'><div class='col-sm-6'><div class='form-group'>"
      if options[:clear] then
        res << "<div class='input-group date'>"
      end
      res << "<input type='datetime' class='form-control' name='#{input_name}' id='#{id}' readonly data-ts='#{timestamp}' />"
      if options[:clear] then
        res << "<span class='input-group-addon' id='#{id}_clear'><span class='fas fa-times'></span></span></div>"
      end
      res << "</div></div></div></div><script type='text/javascript'>$(function () { var dt = $('##{id}'); dt.datetimepicker({ #{jsOpts}ignoreReadonly: true, locale: '#{js_locale}', format: '#{js_format}' }); if (dt.length > 0 && dt.data['ts'] != '') { $('##{id}').data('DateTimePicker').date(moment($('##{id}').data('ts'))); }"
      if options[:clear] then
        res << "$('##{id}_clear').click(function() { $('##{id}').data('DateTimePicker').clear(); });"
      end
      res << "});</script></div>"
      res.html_safe
    end

    # Returns Bootstrap button group for choosing a specified enum attribute (identified by +name+) on an object
    # assigned to the template (identified by +object+). Additional options on the input tag can be passed as a
    # hash with +options+. The supported options are shown in the following examples.
    #
    # ==== Examples
    #   Specify custom label (otherwise, a humanized version of +name+ is used)
    #   # => enum_btn_group(:car, :type, label: "Car type")
    #
    #   Specify custom button names for enum values (a hash)
    #   # => enum_btn_groups(:car, :type, btn_names: { diesel: "Diesel car", electric: "Electric car" })
    #
    #   Specify custom CSS style on the element
    #   # => enum_btn_group(:car, :type, style: "background-color: #000; margin-top: 20px;")
    #
    #   Specify custom CSS classes on the element
    #   # => enum_btn_group(:car, :type, class: "class1 class2")
    def enum_btn_group(name, options = {})
      id = "#{@object_name}_#{name.to_s}"
      input_name = "#{@object_name}[#{name.to_s}]"

      enum_vals = @object.class.send(name.to_s.pluralize)
      btn_names = Hash[enum_vals.keys.collect { |k| [k, k] }]
      if options[:btn_names] then
        btn_names = options[:btn_names]
      end
      btn_names = HashWithIndifferentAccess.new(btn_names)

      label = name.to_s.humanize
      if options[:label] then
        label = options[:label]
      end

      style_str = ""
      if options[:style] then
        style_str = " style='#{options[:style]}'"
      end

      class_str = ""
      if options[:class] then
        class_str = " #{options[:class]}"
      end

      res = ""
      res << "<div class='form-group#{class_str}'#{style_str}>"
      res << "<label for='#{id}'>#{label}</label>"
      res << "<br>"
      res << "<div class='btn-group' data-toggle='buttons'>"
      enum_vals.keys.each do |val|
        active = @object.send("#{val}?")
        active_str = active ? " active" : ""
        checked_str = active ? " checked='checked'" : ""

        res << "<label class='btn btn-toggle#{active_str}'>"
        res << "<input type='radio' value='#{val}' name='#{input_name}' id='#{id}_#{val}'#{checked_str}>"
        res << btn_names[val]
        res << "</label>"
      end
      res << "</div>"
      res << "</div>"
      res.html_safe
    end

    # Returns color picker as a dropdown (<select>) of colors, tailored for accessing a specified color
    # attribute (identified by +name+) on an object assigned to the template (identified by +object+).
    # List of colors must be provided (identified by +colors+). Colors must be a list of hashed hex values
    # (e.g. '#ff0000'). Additional options on the input tag can be passed as a hash with +options+.
    # The supported options are shown in the following examples.
    #
    # ==== Examples
    #   Specify custom CSS style on the element
    #   # => color_picker_select(:tag, :color, colors: ["#ff0000", "#00ff00"], style: "background-color: #000; margin-top: 20px;")
    #
    #   Specify custom CSS classes on the element
    #   # => color_picker_select(:tag, :color, colors: ["#ff0000", "#00ff00"], class: "class1 class2")
    def color_picker_select(name, colors, options = {})
      id = "#{@object_name}_#{name.to_s}"
      input_name = "#{@object_name}[#{name.to_s}]"

      style_str = ""
      if options[:style] then
        style_str = "style='#{options[:style]}'"
      end

      class_str = ""
      if options[:class] then
        class_str = "class='#{options[:class]}'"
      end

      res = ""
      res << "<select name='#{input_name}' id='#{id}' #{style_str} #{class_str}>"
      colors.each do |color|
          res << "<option value='#{color}' data-color='#{color}'></option>"
      end
      res << "</select>"
      res << "<script>$(function() { $('select##{id}').colorselector(); });</script>"
      res.html_safe
    end

    # Returns color picker as a button group of color buttons, tailored for accessing a specified color
    # attribute (identified by +name+) on an object assigned to the template (identified by +object+).
    # List of colors must be provided (identified by +colors+). Colors must be a list of hashed hex values
    # (e.g. '#ff0000'). Additional options on the input tag can be passed as a hash with +options+.
    # The supported options are shown in the following examples.
    #
    # ==== Examples
    #   Specify custom label (otherwise, a humanized version of +name+ is used)
    #   # => color_picker_btn_group(:tag, :color, colors: ["#ff0000", "#00ff00"], label: "Choose color")
    #
    #   Specify size (available options: :large, :normal, :small, :extra_small)
    #   # => color_picker_btn_group(:tag, :color, colors: ["#ff0000", "#00ff00"], size: :small)
    #
    #   Set the picker as vertical
    #   # => color_picker_btn_group(:tag, :color, colors: ["#ff0000", "#00ff00"], vertical: true)
    #
    #   Specify custom CSS style on the element
    #   # => color_picker_btn_group(:tag, :color, colors: ["#ff0000", "#00ff00"], style: "background-color: #000; margin-top: 20px;")
    #
    #   Specify custom CSS class on the element
    #   # => color_picker_btn_group(:tag, :color, colors: ["#ff0000", "#00ff00"], class: "custom")
    def color_picker_btn_group(name, colors, options = {})
      id = "#{@object_name}_#{name.to_s}"
      input_name = "#{@object_name}[#{name.to_s}]"

      icon_str = '<span class="fas fa-check" aria-hidden="true"></span>'
      icon_str_hidden = '<span class="fas fa-check" aria-hidden="true" style="display: none;"></span>'

      label = name.to_s.humanize
      if options[:label] then
        label = options[:label]
      end

      group_str = "btn-group"
      if options[:vertical] and options[:vertical] == true then
        group_str << "-vertical"
      end
      if options[:size] then
        if options[:size] == :large
          group_str << " btn-group-lg"
        elsif options[:size] == :small
          group_str << " btn-group-sm"
        elsif options[:size] == :extra_small
          group_str << " btn-group-xs"
        end
      end

      style_str = ""
      if options[:style] then
        style_str = "style='#{options[:style]}'"
      end

      class_str = ""
      if options[:class] then
        class_str = "#{options[:class]}"
      end

      res = ""
      res << "<div class='form-group #{class_str}' #{style_str}>"
      res << "<label class='control-label required' for='#{id}'>#{label}</label>"
      res << "<div class='#{group_str}' role='group' data-toggle='buttons' aria-label='#{label}' #{style_str}>"
      colors.each_with_index do |color, i|
        active = i == 0 ? " active" : ""
        checked = i == 0 ? " checked='checked'" : ""
        contents = i == 0 ? icon_str : icon_str_hidden

        res << "<label class='btn color-picker btn-primary#{active}' style='background-color: #{color}; min-width: 60px;'>"
        res << "<input type='radio' value='#{color}'#{checked} name='#{input_name}' id='#{id}_#{color}'>"
        res << "#{contents}&nbsp;"
        res << "</label>"
      end
      res << "</div>"
      res << "<script type='text/javascript'>$(function () {"
      res << "$('.btn.btn-primary.color-picker').click(function() {"
      res << "var els = $('.btn.btn-primary.color-picker'); for (var i = 0; i < els.length; i++) {"
      res << "var el = $(els[i]); el.find('span').hide(); }"
      res << "$(this).find('span').show(); });"
      res << "});</script>"
      res << "</div>"
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
        if opts[:rows]
          opts[:class] = [opts[:class], 'textarea-sm-present'].join(' ')
        else
          opts[:class] = [opts[:class], 'textarea-sm'].join(' ')
        end
      end
      text_area(name, opts)
    end

    # Returns <textarea> helper tag for tinyMCE editor
    def tiny_mce_editor(name, options = {})
      options.merge!(cols: 120, rows: 10)
      text_area(name, options)
    end
  end
end
