class Sitio < ActiveRecord::Base
  attr_accessible :idEmpresa, :idZona, :sufijo, :nombreWeb, :mapa, :ipServer, :baseFacEle, :basePdv, :nombre
 
end
