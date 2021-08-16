# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawProjectHeader
  def draw_project_header(subject)
<<<<<<< HEAD
<<<<<<< HEAD
    project = subject.project
    return unless project && can_read_project?(@user, project)
=======
module DrawProjectHeader
=======
module Reports::Docx::DrawProjectHeader
>>>>>>> Initial commit of 1.17.2 merge
  def draw_project_header(subject)
    project = Project.find_by_id(subject['id']['project_id'])
    return unless project
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    project = Project.find_by(id: subject['id']['project_id'])
=======
    project = subject.project
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    return unless project && can_read_project?(@user, project)
>>>>>>> Pulled latest release

    @docx.p I18n.t('projects.reports.elements.project_header.user_time',
                   timestamp: I18n.l(project.created_at, format: :full))
    @docx.h1 I18n.t('projects.reports.elements.project_header.title', project: project.name)
    @docx.hr do
      size 18
      spacing 24
    end
  end
end
