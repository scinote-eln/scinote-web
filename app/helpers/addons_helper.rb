module AddonsHelper
  def list_all_addons
    Rails::Engine
      .subclasses
      .select { |c| c.name.start_with?('Scinote') }
      .map(&:module_parent)
  end
end
