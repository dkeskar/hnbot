class CreateAvatars < ActiveRecord::Migration
  def self.up
    create_table :avatars do |t|
      t.string      :name
      t.integer     :nwx, :default => 0
      t.boolean     :valid, :default => true
    end
  end

  def self.down
    drop_table :avatars
  end
end
