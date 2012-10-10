class CreateTerms < ActiveRecord::Migration
  def change
    create_table :terms do |t|
      t.string :name
      t.string :source_name
      t.boolean :processed
      t.integer :topic_id

      t.timestamps
    end
  end
end
