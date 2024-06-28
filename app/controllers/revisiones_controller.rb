class RevisionesController < ApplicationController
  include TodosHelper
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :obtiene_catalogos
  before_filter :obtiene_checklists, only: [:revisiones_new, :revisiones_create_preview, :revisiones_create]

  def revisiones
    @filtros = [1]
    get_filtros_for_user(current_user.id)
    sql = "SELECT Revisiones.* FROM Revisiones WHERE ( #{@filtros.join(" ) AND ( ")} ) ORDER BY Revisiones.FechaActualizacion DESC LIMIT 100"
    @revisiones = @dbEsta.connection.select_all(sql)
  end

  def revisiones_new
    @checklist = Checklist.where(status: 1).first
    @checklist_items = ChecklistItem.where("checklist_id = ? AND status = 1", @checklist.id).order("orden,id")
  end

  def revisiones_create_preview
    genera_revision
  end

  def revisiones_create
    genera_revision
    @ids_todos_generados = []
    if @unchecked.count > 0
      @unchecked.each do |i|
        # @reporte.push(" - #{i}")
        id = get_todo_id
        @ids_todos_generados.push(id)
        involucrados = ["u#{current_user.id}","s#{@sucursal}"].join(",")
        asunto = "CheckList No Aprobado: #{i}"
        sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{Time.now.to_i}, #{current_user.id}, #{User.sanitize("Se solicita hacer seguimiento del presente Checklist no aprobado: #{i}")}, now(), now())"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/revisiones_new", alert: "No se ha podido guardar la respuesta del To-Do"
        end
        sql = "INSERT INTO TodosHTodos (IdHTodo, Tipo, Involucrados, Prioridad, Status, CreadoPor, Responsable, Asunto, UltimaRespuesta, FechaCreacion, FechaActualizacion) VALUES ( #{id}, 3, #{User.sanitize(involucrados)}, 2, 1, #{User.sanitize(current_user.id)}, 0, #{User.sanitize(asunto)}, #{User.sanitize(current_user.id)}, now(), now())"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/revisiones_new", alert: "No se ha podido guardar el To-Do"
        end
        logTxt = "To-Do creado por Sistema de Checklists. Usuario: #{getUser(current_user.id)} con involucrados: #{involucrados}, prioridad: #{getPrioridad(2)}, tipo: #{getTipo(3)} y asunto: #{asunto}"
        sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/revisiones_new", alert: "No se ha podido guardar el log del To-Do"
        end        
      end
    end
    id = get_revision_id
    @reporte_con_ids = []
    @reporte.split("\n").each do |row|
      if row.start_with?("Nota: Se generar")
        if @ids_todos_generados.count > 0
          @reporte_con_ids.push("Nota: Se han generado los siguientes To-Dos:\n")
          @ids_todos_generados.each do |i|
            @reporte_con_ids.push(" - ToDo: #{i}: http://#{request.host_with_port}/todos_show?id=#{i}")
          end
        else
          @reporte_con_ids.push("Nota: No se ha generado ningún To-Do.")
        end
      else
        @reporte_con_ids.push(row)
      end
    end
    @reporte_con_ids = @reporte_con_ids.join("\n")
    sql = "INSERT INTO Revisiones (IdRevision, Usuario, Sucursal, Revision, ToDoCreados, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(current_user.id)}, #{User.sanitize(@sucursal)}, #{User.sanitize(@reporte_con_ids)}, #{User.sanitize(@ids_todos_generados.join(","))}, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/revisiones_new", alert: "No se ha podido guardar el To-Do"
    end    
    return redirect_to "/revisiones", notice: "Revisión generada exitosamente. To-Dos generados: #{@ids_todos_generados.count}"
  end

  def revisiones_show
    @filtros = [1]
    get_filtros_for_user(current_user.id)
    @filtros.push("IdRevision = #{params[:id].to_i}")
    sql = "SELECT Revisiones.* FROM Revisiones WHERE ( #{@filtros.join(" ) AND ( ")} ) ORDER BY Revisiones.FechaActualizacion DESC LIMIT 1"
    @revisiones = @dbEsta.connection.select_all(sql)
    return redirect_to "/revisiones", alert: "Revisión no encontrada" if @revisiones.count != 1
    @revision = @revisiones.first
  end

  private

    def obtiene_catalogos
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}
      @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE TipoSuc = 'S' ORDER BY Num_suc").map{|u| ["- Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "#{u['Num_suc']}"]}.uniq rescue []
      @prioridades = [ [ "Normal", 2 ], [ "Baja", 1 ],  [ "Alta", 3 ], [ "Urgente", 4 ] ]
      @tipos = [ [ "Tarea", 1 ], [ "Recordatorio", 2 ], [ "Otro", 3 ] ]
      @status = [ [ "Abierto", 1 ], [ "En Progreso", 2 ], [ "Esperando Respuesta", 3 ],  [ "En Espera", 4 ], [ "Cerrado", 5 ], [ "Desechado", 6 ] ]
    end

    def obtiene_checklists
      @checklist = Checklist.where(status: 1).first
      @checklist_items = ChecklistItem.where("checklist_id = ? AND status = 1", @checklist.id).order("orden,id")
    end

    def get_filtros_for_user(u)
      @filtros.push("Revisiones.Usuario = #{current_user.id}")
    end

    def genera_revision
      @sucursal = params[:sucursal] if params.has_key?(:sucursal)
      @reporte  = ["Fecha: #{Time.now.to_s[0..19]}\n\nRevisión de #{getSucursal(@sucursal)[2..-1]}"]
      @reporte.push("Auditada por: #{getUser(current_user.id)}\n")
      @reporte.push("Checklists Aprobados:\n")
      @checked = []
      @unchecked = []
      @checklist_items.each do |i|
        checkbox = params["cbi-#{i.id}"] if params.has_key?("cbi-#{i.id}")
        if checkbox && checkbox == "1"
          @reporte.push(" - #{i.texto}")
          @checked.push("#{i.texto}")
        else
          @unchecked.push("#{i.texto}")
        end
      end
      @reporte.push(" - Sin Checklists Aprobados") if @checked.count == 0
      @reporte.push("\nChecklists No Aprobados:\n")
      if @unchecked.count > 0
        @unchecked.each do |i|
          @reporte.push(" - #{i}")
        end
        @reporte.push("\nNota: Se generarán los To-Dos para cada checklist no aprobado.\n")
      else
        @reporte.push(" - Sin Checklists no Aprobados\n")
      end
      @reporte = @reporte.join("\n")
    end

end
