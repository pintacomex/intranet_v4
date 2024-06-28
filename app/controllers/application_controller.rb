class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :exception
  before_filter :set_current_empresa
  before_filter :set_sin_navegador
  before_action :set_raven_context

  # before_filter :get_modulos_usuario
  helper_method :get_modulos_usuario
  helper_method :get_current_user_app_nivel
  helper_method :tiene_permiso_de_ver_app_especifica?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def admin_only
    return if current_user.id == 3 # Added for testing
    if !current_user.has_role? :admin
      Rails.logger.info 'Going to redirect from admin only'
      redirect_to '/', notice: "No autorizado / Not authorized" and return
    end
  end

  def set_current_empresa
    @sitio = Sitio.where("nombreWeb like ?", "%#{request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","")}%")

    if @sitio.length < 1
      Rails.logger.info 'Going to redirect from set_current_empresa only'
      redirect_to 'http://www.comex.com.mx' and return
    else
      @dbPdv = PdvDatabase         if @sitio[0].basePdv == "pdv"
      @dbPdv = PdvpaintDatabase    if @sitio[0].basePdv == "pdvpaint"
      @dbPdv = PdvadrahcaDatabase  if @sitio[0].basePdv == "pdvadrahca"
      @dbPdv = PdvsalvadorDatabase if @sitio[0].basePdv == "pdvsalvador"
      @dbPdv = PdvbeliceDatabase   if @sitio[0].basePdv == "pdvbelice"
      @dbPdv = PdvhondurasDatabase   if @sitio[0].basePdv == "pdvhonduras"

      @dbNomina = NominapintaDatabase    if @sitio[0].basePdv == "pdv"
      @dbNomina = NominaspiDatabase      if @sitio[0].baseFacEle == "facelespi"
      @dbNomina = NominasalvadorDatabase if @sitio[0].basePdv == "pdvsalvador"
      @dbNomina = NominabeliceDatabase   if @sitio[0].basePdv == "pdvbelice"
      @dbNomina = NominahondurasDatabase   if @sitio[0].basePdv == "pdvhonduras"

      @dbComun = ComunDatabase         if @sitio[0].basePdv == "pdv"
      @dbComun = ComunpaintDatabase    if @sitio[0].basePdv == "pdvpaint"
      @dbComun = ComunadrahcaDatabase  if @sitio[0].basePdv == "pdvadrahca"
      @dbComun = ComunsalvadorDatabase if @sitio[0].basePdv == "pdvsalvador"
      @dbComun = ComunbeliceDatabase   if @sitio[0].basePdv == "pdvbelice"
      @dbComun = ComunhondurasDatabase   if @sitio[0].basePdv == "pdvhonduras"

      @dbFacEle = FacelepintaDatabase    if @sitio[0].baseFacEle == "facelepinta"
      @dbFacEle = FacelepaintDatabase    if @sitio[0].baseFacEle == "facelepaint"
      @dbFacEle = FaceleadrahcaDatabase  if @sitio[0].baseFacEle == "faceleadrahca"
      @dbFacEle = FaceleadrahcaDatabase  if @sitio[0].baseFacEle == "facelespi"
      @dbFacEle = FacelesalvadorDatabase if @sitio[0].baseFacEle == "facelesalvador"
      @dbFacEle = FacelebeliceDatabase   if @sitio[0].baseFacEle == "facelebelice"
      @dbFacEle = FacelehondurasDatabase   if @sitio[0].baseFacEle == "facelehonduras"

      @dbTrab = TrabpintaDatabase    if @sitio[0].basePdv == "pdv"
      @dbTrab = TrabpaintDatabase    if @sitio[0].basePdv == "pdvpaint"
      @dbTrab = TrabadrahcaDatabase  if @sitio[0].basePdv == "pdvadrahca"
      @dbTrab = TrabsalvadorDatabase if @sitio[0].basePdv == "pdvsalvador"
      @dbTrab = TrabbeliceDatabase   if @sitio[0].basePdv == "pdvbelice"
      @dbTrab = TrabhondurasDatabase if @sitio[0].basePdv == "pdvhonduras"

      @dbEsta = EstapintaDatabase    if @sitio[0].basePdv == "pdv"
      @dbEsta = EstapaintDatabase    if @sitio[0].basePdv == "pdvpaint"
      @dbEsta = EstaadrahcaDatabase  if @sitio[0].basePdv == "pdvadrahca"
      @dbEsta = EstasalvadorDatabase if @sitio[0].basePdv == "pdvsalvador"
      @dbEsta = EstabeliceDatabase   if @sitio[0].basePdv == "pdvbelice"
      @dbEsta = EstahondurasDatabase if @sitio[0].basePdv == "pdvhonduras"

      @dbVentasonline = VentasonlinepintaDatabase
      @dbVentasonline = VentasonlinesalvadorDatabase if @sitio[0].basePdv == "pdvsalvador"
      @dbVentasonline = VentasonlinebeliceDatabase if @sitio[0].basePdv == "pdvbelice"
      @dbVentasonline = VentasonlinehondurasDatabase if @sitio[0].basePdv == "pdvhonduras"

      @nomDbPdv = "pdv."        if @sitio[0].basePdv == "pdv"
      @nomDbPdv = "pdvpaint."   if @sitio[0].basePdv == "pdvpaint"
      @nomDbPdv = "pdvadrahca." if @sitio[0].basePdv == "pdvadrahca"
      @nomDbPdv = "pdvsalvador." if @sitio[0].basePdv == "pdvsalvador"
      @nomDbPdv = "pdvbelice." if @sitio[0].basePdv == "pdvbelice"
      @nomDbPdv = "pdvhonduras." if @sitio[0].basePdv == "pdvhonduras"

      @nomDbComun = "comun."        if @sitio[0].basePdv == "pdv"
      @nomDbComun = "comunpaint."   if @sitio[0].basePdv == "pdvpaint"
      @nomDbComun = "comunadrahca." if @sitio[0].basePdv == "pdvadrahca"
      @nomDbComun = "comunsalvador." if @sitio[0].basePdv == "pdvsalvador"
      @nomDbComun = "comunbelice." if @sitio[0].basePdv == "pdvbelice"
      @nomDbComun = "comunhonduras." if @sitio[0].basePdv == "pdvhonduras"

      @nomDbFacEle = "facelepinta."   if @sitio[0].baseFacEle == "facelepinta"
      @nomDbFacEle = "facelepaint."   if @sitio[0].baseFacEle == "facelepaint"
      @nomDbFacEle = "faceleadrahca." if @sitio[0].baseFacEle == "faceleadrahca"
      @nomDbFacEle = "facelesalvador." if @sitio[0].baseFacEle == "facelesalvador"
      @nomDbFacEle = "facelebelice." if @sitio[0].baseFacEle == "facelebelice"
      @nomDbFacEle = "facelehonduras." if @sitio[0].baseFacEle == "facelehonduras"

      @nomDbTrab = "trabpinta."   if @sitio[0].basePdv == "pdv"
      @nomDbTrab = "trabpaint."   if @sitio[0].basePdv == "pdvpaint"
      @nomDbTrab = "trabadrahca." if @sitio[0].basePdv == "pdvadrahca"
      @nomDbTrab = "trabsalvador." if @sitio[0].basePdv == "pdvsalvador"
      @nomDbTrab = "trabbelice." if @sitio[0].basePdv == "pdvbelice"
      @nomDbTrab = "trabhonduras." if @sitio[0].basePdv == "pdvhonduras"

      @nomDbEsta = "estapinta."   if @sitio[0].basePdv == "pdv"
      @nomDbEsta = "estapaint."   if @sitio[0].basePdv == "pdvpaint"
      @nomDbEsta = "estaadrahca." if @sitio[0].basePdv == "pdvadrahca"
      @nomDbEsta = "estasalvador." if @sitio[0].basePdv == "pdvsalvador"
      @nomDbEsta = "estabelice." if @sitio[0].basePdv == "pdvbelice"
      @nomDbEsta = "estahonduras." if @sitio[0].basePdv == "pdvhonduras"

      @nomDbPub = "pubpinta."   if @sitio[0].basePdv == "pdv"
      @nomDbPub = "pubpaint."   if @sitio[0].basePdv == "pdvpaint"
      @nomDbPub = "pubadrahca." if @sitio[0].basePdv == "pdvadrahca"
      @nomDbPub = "pubsalvador." if @sitio[0].basePdv == "pdvsalvador"
      @nomDbPub = "pubbelice." if @sitio[0].basePdv == "pdvbelice"
      @nomDbPub = "pubhonduras." if @sitio[0].basePdv == "pdvhonduras"

      @nomDbShared = "sharedpinta."   if @sitio[0].basePdv == "pdv"
      @nomDbShared = "sharedpaint."   if @sitio[0].basePdv == "pdvpaint"
      @nomDbShared = "sharedadrahca." if @sitio[0].basePdv == "pdvadrahca"
      @nomDbShared = "sharedsalvador." if @sitio[0].basePdv == "pdvsalvador"
      @nomDbShared = "sharedbelice." if @sitio[0].basePdv == "pdvbelice"
      @nomDbShared = "sharedhonduras." if @sitio[0].basePdv == "pdvhonduras"

      @nomCia = "Pintacomex, S.A. de C.V."             if @sitio[0].basePdv == "pdv"
      @nomCia = "Baja Paint, S.A. de C.V."             if @sitio[0].basePdv == "pdvpaint"
      @nomCia = "Administraciones Rahca, S.A. de C.V." if @sitio[0].basePdv == "pdvadrahca"
      @nomCia = "El Salvador, S.A. de C.V."            if @sitio[0].basePdv == "pdvsalvador"
      @nomCia = "Comex Belize"                         if @sitio[0].basePdv == "pdvbelice"
      @nomCia = "Comex Honduras"                       if @sitio[0].basePdv == "pdvhonduras"
    end
  end

  def get_modulos_usuario
    get_modulos_app_rol_nivel
  end

  def get_modulos_app_rol_nivel
    return if !current_user
    return if self.class.parent == Admin
    @user_permisos = { nivel: 100, idEmpresa: 0, numEmpleado: 0 }
    nivel      = Permiso.select("permisos.*, cat_roles.nivel").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").joins("LEFT JOIN cat_roles ON nomPermiso = permiso").order("nivel DESC").limit(1).first.nivel.to_i rescue -1
    @user_permisos[:nivel] = nivel if nivel >= 0
    # Antes se tomaba el numEmpleado de permisos. Ahora de la tabla users
    if current_user.idEmpresa.to_i > 0 and current_user.numEmpleado.to_i > 0
      @user_permisos[:idEmpresa]   = current_user.idEmpresa.to_i
      @user_permisos[:numEmpleado] = current_user.numEmpleado.to_i
    end
    # Aqui se deciden los modulos individualmente
    # Cuando se crea un nuevo modulo hay que agregarlo a /admin/apps y activarlo para usuarios en /app_rol_nivel
    @modulos = []
    @modulos.push({ url: "comprobantes_nomina", nombre: "Comprobantes de Nómina", bloque: "Personal", escondido: 0 }) if @user_permisos[:numEmpleado] > 0
    @modulos.push({ url: "contrato_colectivo", nombre: "Contrato Colectivo de Trabajo", bloque: "Personal", escondido: 0 }) if ( @user_permisos[:numEmpleado] > 0 and @user_permisos[:idEmpresa] == 1 )

    if @user_permisos[:nivel] >= 0
      sql = "SELECT apps.id, apps.url, apps.nombre, apps.bloque, app_rol_nivels.nivel FROM apps LEFT JOIN app_rol_nivels ON apps.id = app_rol_nivels.app AND app_rol_nivels.rol = #{@user_permisos[:nivel]} WHERE (activo = 1)"
      ActiveRecord::Base.connection.execute(sql).each do |app|
        if ( app[4] && app[4] > 0 ) || ( current_user.has_role? :admin )
          nivel = app[4]
          nivel = 2 if current_user.has_role? :admin
          @modulos.push({ app_id: app[0], url: app[1], nombre: app[2], bloque: app[3], nivel: nivel, nivel_app_rol_nivels: app[4], escondido: 0 })
        end
      end
    end
    @modulos.sort_by! { |k| [ k[:bloque], k[:nombre] ] }
    @bloques = @modulos.map{ |k| k[:bloque] }.uniq
  end

  def tiene_permiso_de_ver_app
    get_modulos_app_rol_nivel if !@modulos
    if ! ( @modulos.map{|m| m[:url].split("/")[0] }.include?(controller_path.split('/').first) )
      Rails.logger.info 'Going to redirect from tiene_permiso_de_ver_app only'
      redirect_to '/', notice: "No autorizado / Not authorized #{controller_path.split('/')}" and return
    end
  end

  def tiene_permiso_de_ver_app_especifica?(nombre_app)
    get_modulos_app_rol_nivel if !@modulos
    if ! ( @modulos.map{|m| m[:url].split("/")[0] }.include?(nombre_app) )
      return false
    else
      return true
    end
  end

  def tiene_permiso_de_escritura
    get_modulos_app_rol_nivel if !@modulos
    @modulos.each do |m|
      if m[:url].split("/")[0] == controller_name
        return true if m[:nivel] == 2
      end
    end
    return false
  end

  def set_sin_navegador
    @sin_navegador = true if user_signed_in? and params.has_key?(:sin_navegador) and params[:sin_navegador] == "1"
  end

  def fix_show_date(d)
    d = "#{d[0..3]}-#{d[4..5]}-#{d[6..7]}" if d.to_s.length == 8
    return d
  end

  def tiene_permiso_de_ver_modulo(nivel_minimo)
    get_modulos_usuario
    if @user_permisos[:nivel] > nivel_minimo
      Rails.logger.info 'Going to redirect from tiene_permiso_de_ver_modulo only'
      redirect_to '/', notice: "No autorizado / Not authorized" and return
    end
  end

  def get_modulos_personalizados
    menu_customize = MenuCustomize.where(idUsuario: current_user.id)
    menu_customize.each do |m|
      if m.escondido
        modulo = @modulos.select { |a| a[:url] == m.modulo }.first
        modulo[:escondido] = 1 if modulo
      end
    end
  end

  def get_modulos_con_bloques
    @modulos.select! { |a| a[:escondido] == 0 }
    @bloques = @modulos.map{ |k| k[:bloque] }.uniq
  end

  def current_permission
    @current_permission ||= Permissions.permission_for(current_user)
  end

  def get_todo_id
    id = 1
    sql = "SELECT max(IdHTodo) as mid FROM TodosHTodos"
    ids = @dbEsta.connection.select_all(sql)
    if ids.count == 1
      id = ids.first['mid'].to_i + 1
    end
    return id
  end

  def get_current_level_app
    nivel      = Permiso.select("permisos.*, cat_roles.nivel").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").joins("LEFT JOIN cat_roles ON nomPermiso = permiso").order("nivel DESC").limit(1).first.nivel.to_i rescue -1
  end

  def get_revision_id
    id = 1
    sql = "SELECT max(IdRevision) as mid FROM Revisiones"
    ids = @dbEsta.connection.select_all(sql)
    if ids.count == 1
      id = ids.first['mid'].to_i + 1
    end
    return id
  end

  def get_current_user_app_nivel
    ret = 0
    get_modulos_app_rol_nivel if !@modulos
    @modulos.each do |m|
      if m[:url].split("/")[0] == controller_path.split('/').first
        ret = m[:nivel_app_rol_nivels].to_i rescue 0
        return ret
      end
    end
    return ret
  end

  def get_external_params
    @p2 = ''
    @p3 = ''
    @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
    if @permiso && @permiso.count == 1
      if @permiso[0].p2 != "" # && @permiso[0].p2 != "0"
        @p2 = @permiso[0].p2.to_s.split(',').map{|i| i.to_i}.sort.join(",")
      end
      if @permiso[0].p3 != "" # && @permiso[0].p3 != "0"
        @p3 = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort.join(",")
      end
    end
  end

  def agregar_params(query)
    query
      .gsub("__p2__", @p2)
      .gsub("__p3__", @p3)
      .gsub("__me__", Date.today.to_s.gsub("-","")[0..5])
      .gsub("__fe__", Date.today.to_s.gsub("-","")[0..7])
  end

  def get_layout_param(row, campo)
    get_external_params
    @campo_query = agregar_params(row[campo])
    @campo = @campo_query.to_s
    if @campo_query.upcase.start_with?('SELECT')
      @campo = @dbEsta.connection.select_all("#{@campo_query} AS Val").first['Val'] rescue ''
    end
    @campo
  end

  private

    def set_raven_context
      Raven.user_context(id: session[:current_user_id]) # or anything else in session
      Raven.extra_context(params: params.to_unsafe_h, url: request.url)
    end

end
