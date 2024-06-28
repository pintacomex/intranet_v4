class CreateNotificaciones < ActiveRecord::Migration
  def change
    create_table :notificaciones do |t|
      t.string :tipo
      t.string :destinatario
      t.string :texto
      t.integer :status
      t.string :deviceId

      t.timestamps null: false
    end
  end
end
