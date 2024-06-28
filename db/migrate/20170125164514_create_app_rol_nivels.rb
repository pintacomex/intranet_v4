class CreateAppRolNivels < ActiveRecord::Migration
  def change
    create_table :app_rol_nivels do |t|
      t.integer :app
      t.integer :rol
      t.integer :nivel

      t.timestamps null: false
    end
  end
end
