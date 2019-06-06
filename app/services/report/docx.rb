class Report::Docx
  include Report::DocxAction::Experiment

  def initialize(json = {},docx)
    @json = json
    @docx = docx
  end

  def draw
    @docx.h1 'Quarterly Report'
  end

end