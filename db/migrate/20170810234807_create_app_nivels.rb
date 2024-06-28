class CreateAppNivels < ActiveRecord::Migration
  def change
    create_table :app_nivels do |t|
      t.integer :app
      t.integer :nivel
      t.string :descripcion

      t.timestamps null: false
    end
  end
end
