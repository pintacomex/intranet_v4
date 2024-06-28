class CreatePermisos < ActiveRecord::Migration
  def change
    create_table :permisos do |t|
      t.integer :idUsuario
      t.string :permiso
      t.string :p1
      t.string :p2
      t.string :p3
      t.string :p4

      t.timestamps null: false
    end
  end
end
