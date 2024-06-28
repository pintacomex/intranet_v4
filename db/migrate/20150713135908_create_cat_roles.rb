class CreateCatRoles < ActiveRecord::Migration
  def change
    create_table :cat_roles do |t|
      t.string :nomPermiso
      t.string :nomP1
      t.string :nomP2
      t.string :nomP3
      t.string :nomP4

      t.timestamps null: false
    end
  end
end
