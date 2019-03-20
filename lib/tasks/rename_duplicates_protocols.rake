# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :protocols do
  desc 'Rename dupluicates protocols '
  task rename_duplicates_team_protocols: :environment do
    # checking for public protocols
    public_protocols = Protocol.select(:name, :team_id)
                               .where.not(name: nil).where(protocol_type: 3)
                               .group(:name, :team_id, :protocol_type)
                               .having('COUNT(*) > 1')
    public_protocols.each do |dup_name|
      protocols_to_update = Protocol.where(
        name: dup_name.name,
        team_id: dup_name.team_id,
        protocol_type: 3
      ).order(created_at: :asc)
      protocols_to_update.each_with_index do |protocol, index|
        next if index.zero?

        protocol.update(name: "#{protocol.name} (#{index})")
      end
    end

    # checking for private protocols
    private_protocols = Protocol.select(:name, :team_id, :added_by_id)
                                .where.not(name: nil).where(protocol_type: 2)
                                .group(
                                  :name,
                                  :team_id,
                                  :protocol_type,
                                  :added_by_id
                                )
                                .having('COUNT(*) > 1')
    private_protocols.each do |dup_name|
      protocols_to_update = Protocol.where(
        name: dup_name.name,
        team_id: dup_name.team_id,
        protocol_type: 2,
        added_by_id: dup_name.added_by_id
      ).order(created_at: :asc)
      protocols_to_update.each_with_index do |protocol, index|
        next if index.zero?

        protocol.update(name: "#{protocol.name} (#{index})")
      end
    end

    # checking for archived protocols
    archived_protocols = Protocol.select(:name, :team_id, :added_by_id)
                                 .where.not(name: nil).where(protocol_type: 4)
                                 .group(
                                   :name,
                                   :team_id,
                                   :protocol_type,
                                   :added_by_id
                                 )
                                 .having('COUNT(*) > 1')
    archived_protocols.each do |dup_name|
      protocols_to_update = Protocol.where(
        name: dup_name.name,
        team_id: dup_name.team_id,
        protocol_type: 4,
        added_by_id: dup_name.added_by_id
      ).order(created_at: :asc)
      protocols_to_update.each_with_index do |protocol, index|
        next if index.zero?

        protocol.update(name: "#{protocol.name} (#{index})")
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
