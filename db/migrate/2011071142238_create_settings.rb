class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.string      :name, :null => false 
      t.string      :value
      t.string      :ptyp
      
      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
