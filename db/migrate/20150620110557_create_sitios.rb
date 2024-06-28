class CreateSitios < ActiveRecord::Migration
  def change
    create_table :sitios do |t|
	  t.integer :idEmpresa, :limit => 2, :null => false, :default => 0
	  t.integer :idZona, :limit => 2, :null => false, :default => 0
      t.string :nombre, :limit => 30, :null => false, :default => "" 
      t.string :sufijo, :limit => 3, :null => false, :default => "" 
      t.string :nombreWeb, :limit => 30, :null => false, :default => "" 
      t.text :mapa, :null => false
      t.string :ipServer, :null => false, :default => "" 
      t.string :basePdv, :limit => 30, :null => false, :default => "" 
      t.string :baseFacEle, :limit => 30, :null => false, :default => "" 

      t.timestamps
    end
  end
end
