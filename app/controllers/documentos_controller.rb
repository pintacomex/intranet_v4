class DocumentosController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  include ActionView::Helpers::NumberHelper

  def index
    filtra_documentos
  end

  def documentos_admin
    filtra_documentos
  end

  def documentos_admin_new
    @cveantnew = "*"
    @cveantnew = params[:cveant] if params.has_key?(:cveant) && params[:cveant] != "" 
  end

  def documentos_admin_create
    cveant = params[:cveant] if params.has_key?(:cveant)
    clave = params[:clave] if params.has_key?(:clave)
    nombre = params[:nombre] if params.has_key?(:nombre)
    imagen = params[:imagen] if params.has_key?(:imagen)
    archivo = params[:archivo] if params.has_key?(:archivo)
    nota = params[:nota] if params.has_key?(:nota)
    fecha = params[:fecha] if params.has_key?(:fecha)
    numord = params[:numord] if params.has_key?(:numord)
    numord = 5 if numord.length < 1

    return redirect_to "/documentos_admin_new?cveant=#{params[:cveant]}", alert: "Ingresa Nombre de Carpeta ó Documento válido" if clave.length < 2
    return redirect_to "/documentos_admin_new?cveant=#{params[:cveant]}", alert: "Ingresa Título válido" if nombre.length < 2

    sql = "SELECT COUNT(*) as cuantos FROM documentos WHERE Clave = '#{clave}'"
    doctoexiste = @dbEsta.connection.select_all(sql)
    if doctoexiste[0]['cuantos'].to_i > 0
      return redirect_to "/documentos_admin_new?cveant=#{params[:cveant]}", alert: "Carpeta ó Documento Existente, capture otro nombre"
    end

    sql = "INSERT INTO documentos (CveAnt,Clave,Nombre,Imagen,Ubicacion,Nota,Fecha,NumOrd) VALUES ('#{cveant}','#{clave}','#{nombre}','#{imagen}','#{archivo}','#{nota}','#{fecha}','#{numord}')"

    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/documentos_admin_new?cveant=#{params[:cveant]}", alert: "No se ha podido crear la carpeta o documento, error: #{exc.message}"
    end
    redirect_to "/documentos_admin?cveant=#{cveant}", notice: "Carpeta o documento generado exitosamente"    
  end

  def documentos_admin_edit
    cveant = params[:cveant] if params.has_key?(:cveant)
    clave = params[:clave] if params.has_key?(:clave)
    return redirect_to "/documentos_admin?cveant=#{cveant}", notice: "Carpeta o documento no encontrado" if !cveant or cveant == ""

    sql = "SELECT * FROM documentos WHERE cveant = '#{cveant}' and clave = '#{clave}'"
    @doctos = @dbEsta.connection.select_all(sql)
  end

  def documentos_admin_update
    cveant = params[:cveant] if params.has_key?(:cveant)
    clave = params[:clave] if params.has_key?(:clave)
    nombre = params[:nombre] if params.has_key?(:nombre)
    imagen = params[:imagen] if params.has_key?(:imagen)
    archivo = params[:archivo] if params.has_key?(:archivo)
    nota = params[:nota] if params.has_key?(:nota)
    fecha = params[:fecha] if params.has_key?(:fecha)
    numord = params[:numord] if params.has_key?(:numord)

    return redirect_to "/documentos_admin?cveant=#{cveant}", notice: "Carpeta o documento no encontrado x" if !cveant or cveant == "" or !clave or clave == ""
    return redirect_to "/documentos_admin_edit?cveant=#{cveant}&clave=#{clave}", alert: "Ingresa Nombre válido" if nombre.length < 1
    sql = "UPDATE documentos SET Nombre = '#{nombre}',Imagen = '#{imagen}',Ubicacion = '#{archivo}',Nota = '#{nota}',Fecha = '#{fecha}',NumOrd = '#{numord}' WHERE CveAnt = '#{cveant}' and Clave = '#{clave}'"

    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/documentos_admin_edit?cveant=#{cveant}&clave=#{clave}", alert: "No se ha podido guardar la carpeta o documento, error: #{exc.message}"
    end

    redirect_to "/documentos_admin?cveant=#{cveant}", notice: "Carpeta o documento editado exitosamente"    
  end

  def documentos_admin_destroy
    cveant = params[:cveant].to_s if params.has_key?(:cveant)
    clave = params[:clave].to_s if params.has_key?(:clave)
    return redirect_to "/documentos_admin?cveant=#{cveant}", notice: "Carpeta o documento no encontrado" if !cveant or cveant == "" or !clave or clave == ""

    sql = "SELECT COUNT(*) as cuantos FROM documentos WHERE CveAnt = '#{clave}'"
    doctoexiste = @dbEsta.connection.select_all(sql)
    if doctoexiste[0]['cuantos'].to_i > 0
      return redirect_to "/documentos_admin?cveant=#{cveant}", alert: "Esta Carpeta no se puede eliminar, primero elimine su descendencia"
    end

    sql = "DELETE FROM documentos WHERE CveAnt = '#{cveant}' and Clave = '#{clave}'"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/documentos_admin?cveant=#{cveant}", alert: "No se ha podido borrar la carpeta o documento, error: #{exc.message}"    
    end
    if cveant == "*"
      redirect_to "/documentos_admin", notice: "Carpeta o documento borrado exitosamente"
    else
      redirect_to "/documentos_admin?cveant=#{cveant}", notice: "Carpeta o documento borrado exitosamente" 
    end
  end

  def documentos_admin_image
    @documentos_image  = DocumentosImage.new
  end

  def documentos_admin_file
    @documentos_file  = DocumentosFile.new
  end

  def documentos_admin_multiple_files
    @documentos_file  = DocumentosFile.new
  end

  private 

    def get_filtros_from_user
        @filtros = []
        @filtros.push("1")
        return @filtros
    end

    def filtra_documentos
      cveant = "*"
      @cveant_r = "*"
      continua = "1"

      if params.has_key?(:regreso) && params[:regreso] == "1"
        sql = "SELECT CveAnt FROM documentos where Clave = '" + params[:cveant] + "'"
        sql = "SELECT CveAnt FROM documentos where CveAnt = '" + params[:cveant] + "'" if params.has_key?(:editado)
        @regreso = @dbEsta.connection.select_all(sql)
        @cveant_r = @regreso[0]['CveAnt'] if (params[:cveant] != "" or params[:cveant] != "*") && !params.has_key?(:baja)
        @cveant_r = params[:cveant] if params.has_key?(:baja) && params[:baja] == "1"
        continua = "0" if @cveant_r == "*" or params[:cveant] == ""
      end

      if params.has_key?(:cveant) and continua == "1"
        cveant = params[:cveant] 
        cveant = @regreso[0]['CveAnt'] if params.has_key?(:regreso) && params[:regreso] == "1" && !params.has_key?(:baja)
        cveant = params[:cveant] if params.has_key?(:baja) && params[:baja] == "1"
        sql = "SELECT CveAnt,Nombre FROM documentos where Clave = '" + cveant + "'"
        sql = "SELECT CveAnt,Nombre FROM documentos where CveAnt = '" + cveant + "'" if params.has_key?(:editado)
        @anterior = @dbEsta.connection.select_all(sql)
      end

      sql = "SELECT CveAnt,Clave,Nombre,Imagen,Ubicacion,Nota,Fecha,NumOrd FROM documentos where CveAnt = '" + cveant + "' order by NumOrd"
      @documentos = @dbEsta.connection.select_all(sql)

      sql = "SELECT count(*) as con_nota FROM documentos where CveAnt = '" + cveant + "' and nota != ''"
      @cuantos = @dbEsta.connection.select_all(sql)

      respond_to do |format|
          format.html
      end        
    end

end
