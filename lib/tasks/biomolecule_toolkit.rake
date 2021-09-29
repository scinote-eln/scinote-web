# frozen_string_literal: true

namespace :biomolecule_toolkit do
  desc 'Creates new BMT inventory and maps BMT macromolecules attributes to its columns'
  task :init_repository, [:team_id] => :environment do |_, args|
    raise StandardError, 'BMT repository already exists!' if BmtRepository.any?

    bmt_client = BiomoleculeToolkitClient.new
    attributes = bmt_client.list_attributes

    team = Team.find(args[:team_id])
    BmtRepository.transaction do
      repository = BmtRepository.create!(name: 'Biomolecule registry', team: team, created_by: team.created_by)
      attributes.each do |attribute|
        repository.repository_columns.create!(name: attribute['name'],
                                              data_type: 'RepositoryTextValue',
                                              created_by: team.created_by)
      end
    end
  end

  desc 'Syncs BMT inventory columns with BMT macromolecules attributes'
  task sync_repository: :environment do
    raise StandardError, 'BMT repository does not exist!' if BmtRepository.none?

    bmt_client = BiomoleculeToolkitClient.new
    attributes = bmt_client.list_attributes

    BmtRepository.transaction do
      repository = BmtRepository.take
      attributes.each do |attribute|
        next if repository.repository_columns.find_by(name: attribute['name']).present?

        repository.repository_columns.create!(name: attribute['name'],
                                              data_type: 'RepositoryTextValue',
                                              created_by: repository.created_by)
      end

      repository.repository_columns.each do |repository_column|
        next if attributes.pluck('name').include?(repository_column.name)

        repository_column.destroy!
      end
    end
  end
end
