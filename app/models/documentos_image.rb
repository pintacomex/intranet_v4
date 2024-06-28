class DocumentosImage < ActiveRecord::Base
  attr_accessible :CveAnt, :Clave, :imagen

  has_attached_file :imagen, styles: { medium: "300x300>", thumb: "100x100>" }, default_url: "/documentos_missing/:style/missing.png"
  validates_attachment_content_type :imagen, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]

  before_post_process :allow_only_images

  def allow_only_images
    if !(imagen.content_type =~ %r{^(image|(x-)?application)/(x-png|pjpeg|jpeg|jpg|png|gif)$})
      return false 
    end
  end
end
