class CreateEmpresas < ActiveRecord::Migration
  def change
    create_table :empresas do |t|
      t.integer :idEmpresa, :limit => 2, :null => false, :default => 0
      t.string :nombre, :limit => 50, :null => false, :default => ""
      t.integer :idRfc, :null => false, :default => 0
      t.text :privacidad, :null => false
      t.string :email, :limit => 50, :null => false, :default => ""

      t.timestamps
    end
  end
end
