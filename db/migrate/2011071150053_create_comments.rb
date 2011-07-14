class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer   :avatar_id
      t.string    :name   # denormalized
  
      # These are ids as used by hacker news
      t.string    :pid
      t.string    :cid
      t.string    :parent_cid

      # maintain thread contexts within this document
      t.text      :contexts
      t.text      :responses

      t.string    :text
      t.integer   :pntx
      t.integer   :nrsp, :default => 0
      t.datetime  :posted_at
      
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
