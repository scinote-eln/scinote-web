namespace :protocol_keyword_team do
  desc 'Fixes false team_id on protocol keyword entry [bug SCI-2257] and ' \
       'removes duplicates in the scope of team [bug SCI-2294]'
  task exec: :environment do
    puts '[SciNote] Start processing...'
    Protocol.find_each do |protocol|
      new_keywords = []
      protocol.protocol_keywords.find_each do |protocol_keyword|
        next if protocol.team_id == protocol_keyword.team_id
        # remove protocol keyword from protocol
        ProtocolProtocolKeyword.where(
          protocol_id: protocol.id,
          protocol_keyword_id: protocol_keyword.id
        ).destroy_all
        # create new keyword with correct team
        new_keywords << ProtocolKeyword.create(
          name: protocol_keyword.name,
          team_id: protocol.team_id
        )
      end
      # append newly created keywords to protocol
      protocol.protocol_keywords << new_keywords
    end

    # remove duplicates
    Team.find_each do |team|
      ActiveRecord::Base.transaction do
        keywords       = team.protocol_keywords
        names          = keywords.pluck(:name)
        duplicates_ids = []
        keywords.each do |keyword|
          duplicates_ids << keyword.id if names.count(keyword.name) > 1
        end

        duplicates_ids.each do |id|
          protocol_keyword = ProtocolKeyword.find_by_id(id)
          next unless protocol_keyword
          duplicates       = keywords.where(name: protocol_keyword.name)
          protocol_ids     = duplicates.map { |k| k.protocols.pluck(:id) }
          duplicates.destroy_all
          new_protocol_keyword = ProtocolKeyword.create!(
            name: protocol_keyword.name,
            team_id: protocol_keyword.team_id
          )
          protocol_ids.flatten.uniq.each do |protocol_id|
            ProtocolProtocolKeyword.create!(
              protocol_id: protocol_id,
              protocol_keyword_id: new_protocol_keyword.id
            )
          end
        end
      end
    end
    puts '[SciNote] Done!'
  end
end
