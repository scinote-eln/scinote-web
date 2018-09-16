module TeamZipExporter
  def self.generate_zip(params, team, current_user)
    Rails.logger.warn('Exporting team zip')

    project_ids = params[:project_ids]
    ids = Project.where(id: project_ids,
                        team_id: team)
      .index_by(&:id)

    options = {team: team}
    zip = TeamZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
      ids,
      :teams,
      options
    )
  end

end
