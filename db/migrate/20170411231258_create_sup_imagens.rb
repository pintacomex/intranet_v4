class CreateSupImagens < ActiveRecord::Migration
  def change
    create_table :sup_imagens do |t|
      t.integer :Sucursal
      t.integer :IdVisita
      t.integer :IdChecklist
      t.integer :IdCatChecklist
      t.integer :IdCampo
      t.integer :Usuario

      t.timestamps null: false
    end
  end
end

