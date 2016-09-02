module SearchHelper
  def experiments_results(tag)
    experiments = []
    tag.my_modules.each do |mod|
      experiments << mod.experiment
    end
    experiments.uniq
  end
  
  def sub_results(el)
    elements = []
    el.each do |m|
      elements << m
    end
    elements.uniq
  end
end
