class CreateZonas < ActiveRecord::Migration
  def change
    create_table :zonas do |t|
      t.integer :idZona, :limit => 2, :null => false, :default => 0
      t.string :nombre, :limit => 50, :null => false, :default => ""

      t.timestamps
    end
  end
end
