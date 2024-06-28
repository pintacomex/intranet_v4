class ReporteDeProblema < ActiveRecord::Base

  attr_accessible :ciudad, :descripcion, :email, :nombre, :sitio

  validates :sitio,   presence: true
  validates :nombre,  length: { maximum: 100 }
  validates :email,   length: { maximum: 100 }
  validates :ciudad,  length: { maximum: 30 }
  validates :descripcion,  length: { maximum: 3000 }

end
