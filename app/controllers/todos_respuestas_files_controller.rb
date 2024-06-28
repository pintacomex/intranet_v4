class TodosRespuestasFilesController < ApplicationController
  before_filter :authenticate_user!

  def create
    @todos_respuestas_file = TodosRespuestasFile.create( todos_respuestas_file_params )
    id = params[:IdHTodo].to_i
    if @todos_respuestas_file.save
      id_respuesta = params[:IdRespuesta].to_i
      sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, File, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{id_respuesta}, #{User.sanitize(current_user.id)}, '', #{@todos_respuestas_file.id}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/todos_show?id=#{id}", alert: "No se ha podido guardar la respuesta del todo"
      end    
      logTxt = "To-Do actualizado por usuario: #{getUser(current_user.id)}. Ha subido nuevo archivo: #{@todos_respuestas_file.file.url}"
      sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/todos_show?id=#{id}", alert: "No se ha podido guardar el log del To-Do"
      end            
    	return redirect_to "/todos_show?id=#{id}", notice: "Archivo agregado correctamente"
    else
    	return redirect_to "/todos_show?id=#{id}", alert: "Error al agregar al archivo"
    end
  end

  private

    def todos_respuestas_file_params
      params.require(:todos_respuestas_file).permit(:IdHTodo, :IdRespuesta, :Usuario, :file)
    end

    def getUser(i)
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}
      return @users.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
    end
end

