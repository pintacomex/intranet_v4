class AddAttachmentImgToSupImagens < ActiveRecord::Migration
  def self.up
    change_table :sup_imagens do |t|
      t.attachment :img
    end
  end

  def self.down
    remove_attachment :sup_imagens, :img
  end
end

