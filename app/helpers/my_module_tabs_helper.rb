module MyModuleTabsHelper
  # Options can contain the following elements:
  # - id - HTML id of the <li> element
  def my_module_tab_li(my_module, tab, href, active, glyphicon, opts = {})
    return '' unless my_module.shown_tabs.include?(tab)

    res = <<-eos
    <li id="#{opts['id']}" class="#{'active' if active}">
      <a href="#{href}" title="#{t('nav2.modules.' + tab)}">
        <span class="hidden-sm hidden-md">#{t('nav2.modules.' + tab)}</span>
        <span class="hidden-xs hidden-lg glyphicon #{glyphicon}"></span>
      </a>
    </li>
    eos
    res.html_safe
  end

  def my_module_tab_selector_tab_li(my_module, tab, can_uncheck = true)
    res = <<-eos
    <li class="#{'disabled' if my_module_tab_toggle_disabled?(my_module, tab, can_uncheck)}">
      <a href="#" data-tab="#{tab}">
        <input type="checkbox" #{'checked="checked"' if my_module.shown_tabs.include?(tab)}>
        #{t('nav2.modules.' + tab)}
      </a>
    </li>
    eos
    res.html_safe
  end

  private

  def my_module_tab_toggle_disabled?(my_module, tab, can_uncheck)
    my_module.shown_tabs.include?(tab) && !can_uncheck
  end
end
