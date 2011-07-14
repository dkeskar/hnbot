class CreateStreams < ActiveRecord::Migration
  def self.up
    create_table :streams do |t|
      t.string      :sid # mavenn stream id
      t.string      :title
      t.text        :config
      t.text        :cache # cache config in effect
      t.string      :status, :default => 'Active'
      
      t.boolean     :mavenn, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
