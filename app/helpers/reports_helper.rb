module ReportsHelper

def render_new_element(hide)
  render partial: "reports/elements/new_element.html.erb",
        locals: { hide: hide }
end

def render_report_element(element)
  children_html = "".html_safe

  # First, recursively render element's children
  if element.comments? or element.project_header?
    # Render no children
  elsif element.result?
    # Special handling for result comments
    if element.has_children?
      children_html.safe_concat render_new_element(true)
      element.children.each do |child|
        children_html.safe_concat render_report_element(child)
      end
    else
      children_html.safe_concat render_new_element(false)
    end
  else
    if element.has_children?
      element.children.each do |child|
        children_html.safe_concat render_new_element(false)
        children_html.safe_concat render_report_element(child)
      end
    end
    children_html.safe_concat render_new_element(false)
  end

  view = "reports/elements/#{element.type_of}_element.html.erb"
  locals = { children: children_html }
  if element.project_header?
    locals[:project] = element.element_reference
  elsif element.my_module?
    locals[:my_module] = element.element_reference
  elsif element.step?
    locals[:step] = element.element_reference
  elsif element.result_asset?
    locals[:result] = element.element_reference
  elsif element.result_table?
    locals[:result] = element.element_reference
  elsif element.result_text?
    locals[:result] = element.element_reference
  elsif element.my_module_activity?
    locals[:my_module] = element.element_reference
    locals[:order] = element.sort_order
  elsif element.my_module_samples?
    locals[:my_module] = element.element_reference
    locals[:order] = element.sort_order
  elsif element.step_checklist?
    locals[:checklist] = element.element_reference
  elsif element.step_asset?
    locals[:asset] = element.element_reference
  elsif element.step_table?
    locals[:table] = element.element_reference
  elsif element.step_comments?
    locals[:step] = element.element_reference
    locals[:order] = element.sort_order
  elsif element.result_comments?
    locals[:result] = element.element_reference
    locals[:order] = element.sort_order
  elsif element.project_activity?
    # TODO
  elsif element.project_samples?
    # TODO
  end

  return (render partial: view, locals: locals).html_safe
end

end
