class DocumentosFilesController < ApplicationController
  before_filter :authenticate_user!

  def create
    @documentos_file = DocumentosFile.create( documentos_file_params )
    idCveAnt = params[:CveAnt]
    idClave = params[:Clave]

    # pry

    if @documentos_file.save
      sql = "UPDATE documentos SET Ubicacion = #{@documentos_file.id} Where CveAnt =  '#{idCveAnt}' and Clave = '#{idClave}'"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/documentos_admin?cveant=#{idCveAnt}", alert: "No se ha podido guardar el archivo"
      end    
   	  return redirect_to "/documentos_admin?cveant=#{idCveAnt}", notice: "Archivo agregada correctamente"
    else
    	return redirect_to "/documentos_admin?cveant=#{idCveAnt}", alert: "Error al agregar el archivo"
    end
  end

  private

    def documentos_file_params
      params.require(:documentos_file).permit(:CveAnt, :Clave, :file)
    end
end
