class CreateAuthLog < ActiveRecord::Migration
  def change
    create_table :auth_logs do |t|
      t.integer :empresa
      t.integer :sucursal
      t.integer :pc
      t.string :numAuth
      t.integer :nivel
      t.datetime :fechaHora
      t.text :descripcion
      t.string :status
      t.text :respuesta
      t.integer :pdvPrueba, default: 0

      t.timestamps null: false
    end
    add_index :auth_logs, :numAuth, :unique => true
  end
end

