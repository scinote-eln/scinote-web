class RenameNonUniqueSampleTypesGroups < ActiveRecord::Migration
  def up
    Organization.find_each do |org|
      st_ids = []
      org.sample_types.find_each do |st|
        if SampleType.where(organization_id: org.id)
                     .where(name: st.name).count > 1
          st_ids << st.id
        end
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

    Organization.find_each do |org|
      sg_ids = []
      org.sample_groups.find_each do |sg|
        if SampleGroup.where(organization_id: org.id)
                      .where(name: sg.name).count > 1
          sg_ids << sg.id
        end
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
