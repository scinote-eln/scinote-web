module MyModuleTabsHelper
  # Options can contain the following elements:
  # - id - HTML id of the <li> element
  # - href - If route to the tab is different than
  #          <tab>_my_module_path(my_module)
  def my_module_tab_li(my_module, tab, active, glyphicon, opts = {})
    return '' unless my_module.shown_tabs.include?(tab)

    title = sanitize(t("nav2.modules.#{tab}"))
    if opts['href'].blank?
      opts['href'] = send("#{tab}_my_module_path", my_module)
    end

    res = <<-eos
    <li id="#{opts['id']}" class="#{'active' if active}">
      <a href="#{opts['href']}" title="#{title}">
        <span class="hidden-sm hidden-md">#{title}</span>
        <span class="hidden-xs hidden-lg glyphicon #{sanitize(glyphicon)}"></span>
      </a>
    </li>
    eos
    res.html_safe
  end

  def my_module_tab_selector_tab_li(my_module, tab)
    toggle_disabled = my_module_tab_toggle_disabled?(my_module, tab)
    res = <<-eos
    <li class="#{'disabled' if toggle_disabled}">
      <a href="#" data-tab="#{tab}">
        <input type="checkbox"
          #{'checked="checked"' if my_module.shown_tabs.include?(tab)}
          #{'disabled="disabled"' if toggle_disabled}
        >
        #{sanitize(t('nav2.modules.' + tab))}
      </a>
    </li>
    eos
    res.html_safe
  end

  private

  def my_module_tab_toggle_disabled?(my_module, tab)
    my_module.shown_tabs.include?(tab) &&
      !my_module.send("can_uncheck_tab_#{tab}?")
  end
end
