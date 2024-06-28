class SupImagen < ActiveRecord::Base
  attr_accessible :Sucursal, :IdVisita, :IdChecklist, :IdCatChecklist, :IdCampo, :Usuario, :img

  has_attached_file :img, styles: { medium: "300x300>", thumb: "100x100>" }, default_url: "/sup_imagens/:style/missing.png"
  validates_attachment_content_type :img, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]

  before_post_process :allow_only_images

  def allow_only_images
    if !(img.content_type =~ %r{^(image|(x-)?application)/(x-png|pjpeg|jpeg|jpg|png|gif)$})
      return false 
    end
  end
end
