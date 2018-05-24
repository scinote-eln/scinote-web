namespace :protocol_keyword_team do
  desc 'Fixes false team_id on protocol keyword entry [bug SCI-2257]'
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
    puts '[SciNote] Done!'
  end
end
