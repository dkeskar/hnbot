class CreatePostings < ActiveRecord::Migration
  def self.up
    create_table :postings do |t|
      t.integer     :avatar_id
      t.string      :name # denormalized
      
      t.string      :pid # posting id used by Hacker News
      t.string      :link
      t.string      :title
      t.integer     :pntx
      t.integer     :cmtx
      t.datetime    :posted_at
      t.boolean     :valid, :default => true
      t.integer     :wacx, :default => 0 # watch activity

      # TODO: Excerpt the posting by crawling and parsing the link.
      t.string      :summary  # summary excerpted
      t.text        :thumbs   # img url
      t.boolean     :pinged, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :postings
  end
end
