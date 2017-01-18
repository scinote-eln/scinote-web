class QuillJsScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w(h1 span p br pre ul li strong em u sub sup s a blockquote ol)
    self.attributes = %w(style class spellcheck href target)
  end

  def skip_node?(node)
    node.text?
  end
end
