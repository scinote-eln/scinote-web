# frozen_string_literal: true

module TeamBySubjectModel
  extend ActiveSupport::Concern

  class_methods do
    def team_by_subject(subjects)
      teams = []
      valid_subjects = Extends::ACTIVITY_SUBJECT_CHILDREN
      # Check all activity subject
      valid_subjects.each do |subject, _children|
        next unless subjects[subject]

        parent_array = [subject.to_s.underscore]
        find_parent = true
        # Trying to build parent array
        while find_parent
          possible_parent = valid_subjects.find { |_sub, ch| ((ch || []).include? parent_array[-1].pluralize.to_sym) }
          possible_parent = { Project: nil } if parent_array[-1] == 'experiment'
          if possible_parent
            parent_array.push(possible_parent.flatten[0].to_s.underscore)
          else
            find_parent = false
          end
        end
        # Remove initial object from parent array
        parent_array.shift
        subjects[subject].each do |child|
          child_subject = subject.to_s.constantize.find_by_id(child)
          next unless child_subject

          # Call all parent subjects
          parent_array.each do |parent|
            temp_child_subject = child_subject.public_send(parent)
            # Some fix for protocols in repository
            break unless temp_child_subject

            child_subject = temp_child_subject
          end
          teams.push(child_subject.team_id)
        end
      end
      teams.uniq
    end
  end
end
