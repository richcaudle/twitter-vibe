class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.string :content
      t.integer :sentiment
      t.string :author
      
      t.timestamps
    end
  end
end
