class CreateMedidores < ActiveRecord::Migration
  def change
    create_table :medidores do |t|
      t.string :tipo, null: false, default: "GaugePorcentual"
      t.string :titulo, null: false, default: "Ventas vs Objetivo"
      t.string :subtitulo1, null: false, default: "Objetivo:"
      t.string :subtitulo2, null: false, default: "Alcance:"
      t.text :valor
      t.text :minimo
      t.text :maximo
      t.string :simbolo, null: false, default: "%"
      t.text :opciones
      t.integer :activado, null: false, default: 1
      t.string :roles

      t.timestamps null: false
    end
  end
end

