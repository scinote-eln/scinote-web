class RenameNonUniqueSampleTypesGroups < ActiveRecord::Migration[4.2]
  def up
    Team.find_each do |team|
      st_ids = []
      team.sample_types.find_each do |st|
        next unless SampleType.where(team_id: team.id)
                              .where(name: st.name)
                              .count > 1
        st_ids << st.id
      end

      next if st_ids.count.zero?

      cntr = -1
      SampleType.where(id: st_ids).find_each do |st|
        cntr += 1
        next if cntr.zero?
        new_name = "#{st.name} (#{cntr})"
        st.update(name: new_name)
      end
    end

    Team.find_each do |team|
      sg_ids = []
      team.sample_groups.find_each do |sg|
        next unless SampleGroup.where(team_id: team.id)
                               .where(name: sg.name)
                               .count > 1
        sg_ids << sg.id
      end

      next if sg_ids.count.zero?

      cntr = -1
      SampleGroup.where(id: sg_ids).find_each do |sg|
        cntr += 1
        next if cntr.zero?
        new_name = "#{sg.name} (#{cntr})"
        sg.update(name: new_name)
      end
    end
  end

  def down
  end
end
