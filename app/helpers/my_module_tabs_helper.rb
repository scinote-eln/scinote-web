module MyModuleTabsHelper
  def my_module_tab_li(my_module, my_module_tab, active)
    return '' unless my_module.shown_tabs.include?(my_module_tab[:id])

    title = sanitize(I18n.t(my_module_tab[:display_name]))
    if my_module_tab[:opts]['href'].blank?
      my_module_tab[:opts]['href'] =
        send("#{my_module_tab[:url]}_my_module_path", my_module)
    end

    res = <<-eos
    <li id="#{my_module_tab[:opts]['id']}" class="#{'active' if active}">
      <a href="#{my_module_tab[:opts]['href']}" title="#{title}">
        <span class="hidden-sm hidden-md">#{title}</span>
        <span class="hidden-xs hidden-lg glyphicon #{sanitize(my_module_tab[:glyphicon])}"></span>
      </a>
    </li>
    eos
    res.html_safe
  end

  def my_module_tab_selector_tab_li(my_module, my_module_tab)
    res = <<-eos
    <li class="#{'disabled' if my_module_tab_toggle_disabled?(my_module, my_module_tab)}">
      <a href="#" data-tab="#{my_module_tab[:id]}">
        <input type="checkbox" #{'checked="checked"' if my_module.shown_tabs.include?(my_module_tab[:id])}>
        #{sanitize(I18n.t(my_module_tab[:display_name]))}
      </a>
    </li>
    eos
    res.html_safe
  end

  private

  def my_module_tab_toggle_disabled?(my_module, my_module_tab)
    my_module.shown_tabs.include?(my_module_tab[:id]) &&
      !my_module_tab[:can_uncheck].call(my_module)
  end
end
