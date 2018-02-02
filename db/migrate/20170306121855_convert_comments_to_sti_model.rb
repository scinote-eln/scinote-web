class ConvertCommentsToStiModel < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :type, :string
    add_column :comments, :associated_id, :integer
    add_index :comments, :associated_id

    Comment.find_each do |comment|
      res = ActiveRecord::Base.connection.execute(
        "SELECT my_module_id FROM my_module_comments
         WHERE comment_id = #{comment.id}"
      )
      if res.ntuples > 0
        comment.update_columns(type: 'TaskComment')
        comment.update_columns(associated_id: res[0]['my_module_id'].to_i)
        next
      end

      res = ActiveRecord::Base.connection.execute(
        "SELECT project_id FROM project_comments
         WHERE comment_id = #{comment.id}"
      )
      if res.ntuples > 0
        comment.update_columns(type: 'ProjectComment')
        comment.update_columns(associated_id: res[0]['project_id'].to_i)
        next
      end

      res = ActiveRecord::Base.connection.execute(
        "SELECT result_id FROM result_comments WHERE comment_id = #{comment.id}"
      )
      if res.ntuples > 0
        comment.update_columns(type: 'ResultComment')
        comment.update_columns(associated_id: res[0]['result_id'].to_i)
        next
      end

      res = ActiveRecord::Base.connection.execute(
        "SELECT step_id FROM step_comments WHERE comment_id = #{comment.id}"
      )
      if res.ntuples > 0
        comment.update_columns(type: 'StepComment')
        comment.update_columns(associated_id: res[0]['step_id'].to_i)
        next
      end
    end

    drop_table :sample_comments do |t|
      t.integer :sample_id, null: false
      t.integer :comment_id, null: false
    end

    drop_table :project_comments do |t|
      t.integer :project_id, null: false
      t.integer :comment_id, null: false
    end

    drop_table :my_module_comments do |t|
      t.integer :my_module_id, null: false
      t.integer :comment_id, null: false
    end

    drop_table :result_comments do |t|
      t.integer :result_id, null: false
      t.integer :comment_id, null: false
    end

    drop_table :step_comments do |t|
      t.integer :step_id, null: false
      t.integer :comment_id, null: false
    end
  end
end
