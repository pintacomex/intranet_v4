class HomereportesController < ApplicationController
	before_filter :authenticate_user!

  def index
  	app_id = App.find_by(url: controller_name).id
  	@flag = false
  	@flag = true if params.has_key?(:month)
	  @home_employees = []
	  
	  @home_employees << Userhome.find_by(user_id: current_user.id) if Userhome.find_by(user_id: current_user.id) != nil 
	  area_jefe = Areajefe.find_by(id_user: current_user.id) rescue []

	  # if get_current_level_app < 5
	  # 	sql =  Userhome.where("user_id != #{current_user.id}")
	  # 	sql.each do |s|
	  # 		@home_employees << s
	  # 	end
	  # end
	  if area_jefe != nil
	  	sql = ActiveRecord::Base.connection.exec_query("SELECT id, id_user as user_id, id_area FROM areausers WHERE areausers.id_area = #{area_jefe[:id_area]}")
	  	sql.each do |s|
	  		@home_employees << s
	  	end
	  end
	  @employees = User.all
		@show_arrow = false
		@show_report = false
		@show_boss = false
		@show_report = true if params[:user_id].to_i == current_user.id.to_i || (Userhome.find_by(user_id: current_user.id) && !params.has_key?('user_id'))
		@show_arrow = true if area_jefe != nil  or get_current_level_app < 5
		@show_boss = true if Permiso.where("idUsuario = #{current_user.id} and permiso = 'Director'").length > 0
		@method = __method__.to_s
		date = Date.parse(params[:month]) rescue DateTime.now
		@start_month = Date.new(date.year, date.month)
		@end_month = Date.new(date.year, date.month+1) - 1 rescue 0
		@end_month = Date.civil(date.year, 12, -1) if date.month == 1 && date.month == 12
		@user = current_user.id
		@user = @home_employees.first['user_id'] if Areajefe.where("id_user=#{@user}").length > 0 
		@user = params[:user_id] if params.has_key?(:user_id)
		@user_selected = User.find_by(id: params['user_id'])
		scores = Calificacionreporte.where("user_id = #{@user} and fecha BETWEEN ? AND ?", @start_month.to_s.gsub("-", ""), @end_month.to_s.gsub("-", ""))
		@taskusers = Taskuser.where("id_user=#{@user} and (porc_terminado < 100 or porc_terminado is null) ")
		@tasks = Task.all

		if params.has_key?(:month)
			date = Date.parse(params[:month])
			@start_month = Date.new(date.year, date.month)
			year = date.year
			month = date.month
			month = 1 if date.month == 12
			@end_month = Date.new(year, month+1) - 1
			@end_month = Date.civil(year, 12, -1) if month == 1 && date.month == 12
  	end

		suma = 0
		scores.each { |x|  suma = suma + x.rating.to_f } rescue 0
		@average = (suma / scores.length).round(1) rescue 0

  end

  def log_home_office
  	@users = User.all
  	@log = LogUsuario.all
  end

  def new_area
  	@area_selected = ""
  	@area_selected = Area.find(params[:id_area]) if params.has_key?(:id_area)
  	@areas = Area.all
  	@users = User.all

  	@users_home = Userhome.all
  	@area_jefes = Areajefe.all
  	@area_users = Areauser.all
  end

  def editar_area
  	@users = User.all
  	@users_home = Userhome.all
  	@area = Area.find(params[:id_area])
  	jefes     = Areajefe.where("id_area=#{params[:id_area].to_i}")
  	empleados = Areauser.where("id_area=#{params[:id_area].to_i}")
  	@users2 = []
  	@users_home2 = []
  	@users.each do |e| 
  		b = false
  		b = true if jefes.select {|j| j.id_user.to_s == e['id'].to_s }.first
  		@users2      <<  { :id => e.id, :name => e.name , :check => b} 
  	end

  	@users_home.each do |e| 
  		c = false
  		c = true if empleados.select {|j| j.id_user.to_s == e['user_id'].to_s }.first
  		@users_home2 <<  { :id => e.id, :user_id => e.user_id , :check => c} 
  	end
  end

  def edit_task
  	@task = Task.find(params[:task_id].to_i)
  	# @new_task = Task.new  	
  	# @tasks = Task.all
  	@task_user = Taskuser.where("id_task = #{@task.id}")
  	@taskusers = Taskuser.where("id_task = #{@task.id}")
  	@home_employees = Userhome.all
  	@users = User.all
  end

  def edit_taskuser
  	@task_user = Taskuser.find(params[:id])
  	@task = Task.find(@task_user.id_task)
  end

  def update_taskuser
  	if Taskuser.update(params[:id].to_i, :fecha_inicio => "#{params[:fecha_inicio]}", :fecha_limite => "#{params[:fecha_limite]}")
  		flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
	  	redirect_to controller: 'homereportes', action: 'edit_taskuser', id: params[:id]
  	else
  		flash[:danger] = "Hubo un error al guardar los cambios"
	  	redirect_to controller: 'homereportes', action: 'edit_taskuser', id: params[:id]
  	end
  end

  def update_task

  	Task.update(params[:id].to_i, :descripcion => "#{params[:descripcion]}")
  	if params.has_key?(:users_task)
	  	params[:users_task].each_with_index do |m, i|
		  	user_task = Taskuser.new(id_task: params[:id], id_user: m.split("-")[0].to_i, fecha_inicio: params[:fecha_inicio], fecha_limite: params[:fecha_limite], creado_por: current_user.id)
		  	if user_task.save
		  		app_id = App.find_by(url: controller_name).id
	  	 		log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'asignacion de tarea a empleado', created_at: DateTime.now())
	  	 		log_usuario.save!
	  	 		flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
		  		  redirect_to controller: 'homereportes', action: 'edit_task', task_id: params[:id]
		  	else
		  		flash[:danger] = "Hubo un problema al crear su asignación. Su asignación debe ser única"
			  	redirect_to controller: 'homereportes', action: 'edit_task', task_id: params[:id]
			  	return
		  	end
		  end
		else 
			flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
		  redirect_to controller: 'homereportes', action: 'edit_task', task_id: params[:id]
		end
  end

  def create_areaempleado
  	Areauser.where(id_area: params[:area_id].to_i).destroy_all
  	params[:users].each do |u|
  		user = Areauser.where("id_area=#{params[:area_id].to_i} and id_user=#{u.to_i}")
  		unless user.length > 0
  			area_user = Areauser.new(id_area: params['area_id'] , id_user: u.to_i )
	  	 	if area_user.save!
	  	 		app_id = App.find_by(url: controller_name).id
	  	 		log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'asignacion de usuario a area', created_at: DateTime.now())
		  	 	log_usuario.save!
	  		else
	  		  flash[:danger] = "Hubo un error al guardar los cambios"
	  		  redirect_to controller: 'homereportes', action: 'editar_area',  id_area: params['area_id']
	  	  end
  		end 
  	end 
  	flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
	  redirect_to controller: 'homereportes', action: 'editar_area',  id_area: params['area_id']
  end

  def create_areauser
  	Areajefe.where(id_area: params[:area_id].to_i).destroy_all
  	params[:users].each do |u|
  		jefe = Areajefe.where("id_area=#{params[:area_id].to_i} and id_user=#{u.to_i}")
  		unless jefe.length > 0
  			area_jefe = Areajefe.new(id_area: params['area_id'] , id_user: u.to_i )
	  	 	if area_jefe.save!
	  	 		app_id = App.find_by(url: controller_name).id
	  	 		log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'asignacion de jefe a area', created_at: DateTime.now())
		  	 	log_usuario.save!
	  		else
	  		  flash[:danger] = "Hubo un error al guardar los cambios"
	  		  redirect_to controller: 'homereportes', action: 'editar_area',  id_area: params['area_id']
	  	  end
  		end 
  	end 
  	flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
	  redirect_to controller: 'homereportes', action: 'editar_area',  id_area: params['area_id']
  end

  def create_area
  	
  	area = Area.new(name: params[:name].downcase , description: '')

  	if area.save && params.has_key?(:name)
  		app_id = App.find_by(url: controller_name).id
  	 	log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'crear area', created_at: DateTime.now())
  	 	log_usuario.save!
  		flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
	  	redirect_to controller: 'homereportes', action: 'new_area'
  	else
  		flash[:danger] = "Hubo un error al guardar los cambios"
	  	redirect_to controller: 'homereportes', action: 'new_area'
  	end
  end

  def new
  	@user = current_user.id
  	@user = params[:user_id] if params.has_key?(:user_id)
  	@method = __method__.to_s
  	@type = "day"
  	@level = get_current_level_app
  	@taskusers = Taskuser.where("id_user=#{@user} and (porc_terminado < 100 or porc_terminado is null) ")
  	@tasks = Task.all
  	@show_arrow = false
		@show_arrow = true  if Areajefe.where("id_user=#{current_user.id}").length > 0 || get_current_level_app < 5
		@show_activities = false
		@show_activities = true if Userhome.find_by(user_id: @user)
		@user_selected = User.find_by(id: params['user_id'])
	  	if params.has_key?(:day) && params[:day].length <= 8
	  		date = "#{params[:day][0..3]}-#{params[:day][4..5]}-#{params[:day][6..-1]}"
	  		date = "#{params[:fecha][0..3]}-#{params[:fecha][4..5]}-#{params[:fecha][6..-1]}" if params.has_key?(:fecha)
	  	elsif params.has_key?(:week)
	  		@week_finish = date_of_next(params[:week])
	  		@week_start = @week_finish - 6
	  	elsif params.has_key?(:month)
	  		date = Date.parse(params[:month])
	  		@start_month = Date.new(date.year, date.month)
	  		year = date.year
	  		month = date.month
	  		month = 1 if date.month == 12
	  		@end_month = Date.new(year, month+1) - 1
	  		@end_month = Date.civil(year, 12, -1) if month == 1 && date.month == 12
	  	end
	  	if params.has_key?(:view)
	  		if params.has_key?(:day)
	  		date = params[:day]
	  			if params[:day][6..-1] == "00" 
	  				date = params[:day][0..3] + format('%02d', params[:day][4..5].to_i - 1) + (Date.new(params[:day][0..3].to_i, params[:day][4..5].to_i) - 1).to_s[-2..-1]
		  		elsif params[:day] > Date.civil(params[:day][0..3].to_i, params[:day][4..5].to_i , -1).to_s.gsub("-", "")
		  			date = params[:day][0..3] + format('%02d', params[:day][4..5].to_i + 1) + (Date.new(params[:day][0..3].to_i, params[:day][4..5].to_i+1)).to_s[-2..-1]
		  		end
	  			@fecha = date
	  			@type = "day"
	  			@reportes = Homereporte.where(fecha: "#{@fecha[0..3]}-#{@fecha[4..5]}-#{@fecha[6..-1]}", user_id: @user)
	  		elsif params.has_key?(:week)
	  			@type = "week"

	  		elsif params.has_key?(:month)
	  			@type = "month"

	  		end
	  	else
	  		@fecha = DateTime.now.strftime("%Y-%m-%d")
	  		@reportes = Homereporte.where(fecha: "#{@fecha}", user_id: @user)
	  	end
	  	@fecha = params[:fecha] if params.has_key?(:fecha)
	  	@calificacion =Calificacionreporte.find_by(fecha: @fecha.to_s.gsub("-", ""), user_id: @user)
  end

  def create

  	@user = current_user.id
  	@user = params[:user_id] if params.has_key?(:user_id)
  	params[:fecha] = params[:date] if params.has_key?(:date)
  	if params.has_key?(:rating)
  		calificacion = Calificacionreporte.new(fecha: params[:fecha].to_s.gsub("-",""), user_id: @user ,rating: params[:rating].to_i)
  		begin
	  	 	if calificacion.save!
	  	 		app_id = App.find_by(url: controller_name).id
  	 		  log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'guardo calificacion', created_at: DateTime.now())
  	 		  log_usuario.save!
	  			flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
	  			redirect_to controller: 'homereportes', action: 'new', user_id: @user, day: params[:fecha].gsub("-", ""), view: "day" 
	  		end
	  	rescue
	  		flash[:danger] = "Hubo un error al guardar los cambios"
	  		redirect_to controller: 'homereportes', action: 'new', user_id: @user, day: params[:fecha].gsub("-", ""), view: "day" 
	  	end
  	else
  		if params.has_key?(:obj)
  			begin

		  		ActiveRecord::Base.connection.execute("update taskusers set fecha_termina = #{ActiveRecord::Base.sanitize(params[:porc_terminado].to_i == 100 ? DateTime.now.to_s[0..9] : '')}, porc_terminado = #{params[:porc_terminado].to_i}, fecha_procesado = '#{ DateTime.now.to_s[0..9]}' where id_task= #{ActiveRecord::Base.sanitize(params[:descripcion].split('-')[0])} and id_user= #{ActiveRecord::Base.sanitize(current_user.id)}")
		  		app_id = App.find_by(url: controller_name).id
  	 		  log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: "Crear un reporte", created_at: DateTime.now())
  	 		  log_usuario.save!
		  	rescue
		  		flash[:danger] = "Actividad NO Registrada"
			  	return redirect_to controller: 'homereportes', action: 'new', user_id: @user, fecha: params[:fecha]
		  	end
  		end 
	  	reporte = Homereporte.new(user_id: current_user.id ,fecha: "#{params[:fecha][0..3]}-#{params[:fecha][4..5]}-#{params[:fecha][6..-1]}", start: reporte_params[:start].split(" ")[0].to_i, finish: reporte_params[:finish].split(" ")[0].to_i, descripcion: "#{reporte_params[:descripcion].include?("-") ? params[:descripcion].split('-')[1] : reporte_params[:descripcion]}" )
	  	begin
	  	 	if reporte.save!
	  	 		app_id = App.find_by(url: controller_name).id
  	 		  log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: "Crear un reporte", created_at: DateTime.now())
  	 		  log_usuario.save!
	  			flash[:notice] = "Actividad guardada satisfactoriamente"
	  			redirect_to controller: 'homereportes', action: 'new', user_id: @user, day: params[:fecha].gsub("-", ""), view: "day"  
	  		end
	  	rescue Exception => exc 
	  		flash[:alert] = "#{exc.to_s[20..-1]}"
	  		redirect_to controller: 'homereportes', action: 'new', user_id: @user, day: params[:fecha].gsub("-", ""), view: "day"
	  	end
	  end
  end

  def new_employee
  	@employee = Userhome.new
  	@employees = []
  	@home_employees = Userhome.all
  	User.all.each { |u| @employees << "#{u.id}-#{u.name}" }
  end

  def checkjefes
  	
  end

  def create_employee
  	
  	employee = Userhome.new(user_id: params[:id_usuario].split("-")[0].to_i, id_token: params[:id_key], fecha_start: DateTime.now.to_s[0..9])

  	if employee.save && params.has_key?(:id_usuario)
  		app_id = App.find_by(url: controller_name).id
  	 	log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'agregar usuario a home office', created_at: DateTime.now())
  	 	log_usuario.save!
  		flash[:notice] = "Usuario guardado exitósamente"
	  	redirect_to controller: 'homereportes', action: 'new_employee'
  	else
  		flash[:danger] = "El usuario que desea guardar ya existe"
	  	redirect_to controller: 'homereportes', action: 'new_employee'
  	end
  end
  
  def delete_employee
  		employee = ActiveRecord::Base.connection.execute("delete from userhomes where user_id= #{ActiveRecord::Base.sanitize(params[:user_id])}")

  		  Taskuser.where(id_user: params[:user_id].to_i).destroy_all
  			
  			flash[:notice] = "Usuario eliminado satisfactoriamente"
	  	redirect_to controller: 'homereportes', action: 'new_employee'
  end

  def new_task
  	@new_task = Task.new  	
  	@tasks = Task.all
  	@task_user = Taskuser.new
  	@taskusers = Taskuser.all
  	@home_employees = Userhome.all
  	@users = User.all
  end

  def create_task
  	task = Task.new(task_id: params[:id], descripcion: params[:descripcion])

  	if task.save && params.has_key?(:descripcion)
  		app_id = App.find_by(url: controller_name).id
  	 	log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'Guardar tarea', created_at: DateTime.now())
  	 	log_usuario.save!
  		flash[:notice] = "Tarea guardada satisfactoriamente"
	  	redirect_to controller: 'homereportes', action: 'create_taskuser', users_task: params[:users_task], fecha_inicio: params[:fecha_inicio], fecha_limite: params[:fecha_limite], id_task: task.id
  	else
  		flash[:danger] = "Hubo un error al guardar la tarea"
	  	redirect_to controller: 'homereportes', action: 'new_task'
  	end
  end


  def delete_task
  	begin
  		task = ActiveRecord::Base.connection.execute("delete from tasks where id= #{ActiveRecord::Base.sanitize(params[:task_id])}")
  		ActiveRecord::Base.connection.execute("delete from taskusers where id_task= #{ActiveRecord::Base.sanitize(params[:task_id])}")
  		flash[:notice] = "Tarea eliminada satisfactoriamente"
	  	redirect_to controller: 'homereportes', action: 'new_task'
  	rescue
  		flash[:danger] = "Hubo un error al eliminar su tarea"
	  	redirect_to controller: 'homereportes', action: 'new_task'
  	end
  end

  def delete_taskuser
  	begin
  		task = ActiveRecord::Base.connection.execute("delete from taskusers where id = #{ActiveRecord::Base.sanitize(params[:id])}")
  		flash[:notice] = "Los cambios de han guardado satisfactoriamente"
	  	redirect_to controller: 'homereportes', action: 'new_task'
  	rescue
  		flash[:danger] = "Hubo un error al realizar los cambios"
	  	redirect_to controller: 'homereportes', action: 'new_task'
  	end
  end

  def delete_areaempleado
  	begin
  		task = ActiveRecord::Base.connection.execute("delete from areausers where id_user= #{ActiveRecord::Base.sanitize(params[:user_id])} and id_area= #{ActiveRecord::Base.sanitize(params[:area_id])}")
  		flash[:notice] = "Los cambios se guardaron exitósamente"
	  	redirect_to controller: 'homereportes', action: 'new_area'
  	rescue
  		flash[:danger] = "Hubo un problema al realizar los cambios"
	  	redirect_to controller: 'homereportes', action: 'new_area'
  	end
  end

  def delete_areajefe
  	begin
  		task = ActiveRecord::Base.connection.execute("delete from areajeves where id_user= #{ActiveRecord::Base.sanitize(params[:user_id])} and id_area= #{ActiveRecord::Base.sanitize(params[:area_id])}")
  		flash[:notice] = "Todos los cambios de han guardado satisfactoriamente"
	  	redirect_to controller: 'homereportes', action: 'new_area'
  	rescue
  		flash[:danger] = "Hubo un problema al realizar los cambios"
	  	redirect_to controller: 'homereportes', action: 'new_area'
  	end
  end

  def create_taskuser
  	user_task = ""
  	params[:users_task].each_with_index do |m, i|
	  	user_task = Taskuser.new(id_task: params[:id_task], id_user: m.split("-")[0].to_i, fecha_inicio: params[:fecha_inicio], fecha_limite: params[:fecha_limite], creado_por: current_user.id)
	  	if user_task.save
	  		app_id = App.find_by(url: controller_name).id
  	 		log_usuario = LogUsuario.new(id_user: current_user.id, id_app: app_id, accion: "1", descripcion: 'asignacion de tarea a empleado', created_at: DateTime.now())
  	 		log_usuario.save!
	  	else
	  		flash[:danger] = "Hubo un problema al crear su asignación. Su asignación debe ser única"
		  	redirect_to controller: 'homereportes', action: 'new_task'
		  	return
	  	end
	  end
  	flash[:notice] = "Asignación guardada exitósamente"
	  redirect_to controller: 'homereportes', action: 'new_task'
end

  def send_email
  	employees = Userhome.all
  	users = User.all
  	employees.each do |e|	
  		u = users.select {|e| e.user_id.to_s == e['user_id'] }.first
  		last_report = Homereporte.where(user_id: e['user_id']).last
  		if (Date.today - 4).to_s > last_report
  			JustMailer.email_something("#{u.email}", "NO HAZ HECHO TU REPORTE DE HOME OFFICE", "Hola NO haz hecho tus reportes Home Office desde el dìa #{fecha}").deliver_later
  		end
  	end
  end

	def date_of_next(week)
	  date  = Date.parse(week)
	  if date.wday != 6
	  	date += 1 + ((5-date.wday) % 7)
	  else 
	  	date
	  end
	end

	def get_employee(api_key)
		url = "https://desktime.com/api/v2/json/employee?apiKey=#{api_key}&email=#{current_user.email}=67728&date=#{DateTime.now}"
		uri = URI(url)
		response = Net::HTTP.get(uri)
		JSON.parse(response)	
	end

	def get_month_stats(api_key)
		url = "https://desktime.com/api/v2/json/employees?apiKey=#{api_key}&date=#{DateTime.now}&period=month"
		uri = URI(url)
		response = Net::HTTP.get(uri)
		JSON.parse(response)
	end

	def get_day_stats(api_key)
		url = "https://desktime.com/api/v2/json/employees?apiKey=#{api_key}&date=#{DateTime.now}&period=day"
		uri = URI(url)
		response = Net::HTTP.get(uri)
		JSON.parse(response)
	end
  

  private
  	def reporte_params
  		params.permit(:date, :start, :finish, :descripcion)
  	end

  	def calificaciones_params
  		params.permit(:fecha, :rating)
  	end
end