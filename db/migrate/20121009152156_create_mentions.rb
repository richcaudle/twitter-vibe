class CreateMentions < ActiveRecord::Migration
  def change
    create_table :mentions do |t|
      t.integer :tweet_id
      t.integer :term_id

      t.timestamps
    end
  end
end
