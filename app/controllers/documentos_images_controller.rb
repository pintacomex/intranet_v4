class DocumentosImagesController < ApplicationController
  before_filter :authenticate_user!

  def create
    @documentos_image = DocumentosImage.create( documentos_image_params )
    idCveAnt = params[:CveAnt]
    idClave = params[:Clave]
    if @documentos_image.save
      sql = "UPDATE documentos SET Imagen = #{@documentos_image.id} Where CveAnt =  '#{idCveAnt}' and Clave = '#{idClave}'"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/documentos_admin?cveant=#{idCveAnt}", alert: "No se ha podido guardar la imagen"
      end    
      return redirect_to "/documentos_admin?cveant=#{idCveAnt}", notice: "Imagen agregada correctamente"
    else
      return redirect_to "/documentos_admin?cveant=#{idCveAnt}", alert: "Error al agregar la imagen"
    end
  end

  private

    def documentos_image_params
      params.require(:documentos_image).permit(:CveAnt, :Clave, :imagen)
    end
end
