module SearchHelper
  def experiments_results(tag)
    experiments = []
    tag.my_modules.each do |mod|
      experiments << mod.experiment
    end
    experiments.uniq
  end
end
