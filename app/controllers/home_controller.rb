class HomeController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_modo_local, only: [:index, :zammad_create]
  before_filter :get_mimes, only: [:index, :zammad_create]

  def index
    get_modulos_app_rol_nivel
    get_modulos_personalizados
    get_modulos_con_bloques
    return redirect_to "/#{@modulos[0][:url]}/" if @modulos.length == 1
    get_tableros_for_user
    @icons = { 'Antiguedad de Saldos' => 'fa-piggy-bank', 'Bajas de Mercancía' => 'fa-people-carry', 'Obras' => 'fa-diagnoses', 'Notificaciones' => 'fa-bell', 'Supervisiones' => 'fa-user-friends', 'Tickets' => 'fa-tasks', 'Claves PDV' => 'fa-calculator', 'Cálculo de Objetivos' => 'fa-clipboard-list', 'Documentación' => 'fa-paperclip', 'Estadísticas de Ventas' => 'fa-chart-bar', 'Gráficas de Ventas' => 'fa-chart-line', 'Punto de Venta' => 'fa-laptop', 'Reporte Objetivos de Venta' => 'fa-list-alt', 'Reporte Signos Vitales' => 'fa-signal', 'Stock en Sucursales' => 'fa-truck-loading', 'Autorizaciones por App Rol Nivel' => 'fa-lock', 'Webservices' => 'fa-cloud', 'Réplica de las Sucursales' => 'fa-exchange-alt', 'Sistema de Tickets' => 'fa-ticket-alt', 'Status de las Réplicas' => 'fa-rss', 'Cotizaciones' => 'fa-edit', 'Comisiones' => 'fa-money-bill-alt', 'Comisiones V1' => 'fa-money-bill-alt', 'Comprobantes de Nómina' => 'fa-file-alt', 'Monitor de Sucursales' => 'fa-heartbeat', 'Conciliaciones' => 'fa-handshake', 'Home Office' => 'fa-h-square', 'Reportes De Vendedores' => 'fa-file-alt', 'Ecommerce' => 'fa-shopping-cart', 'Consultas' => 'fa-newspaper', 'Reportes BI' => 'fa-cubes', 'Contenedores' => 'fa-truck', 'Bloqueo Tarjetas Club Comex' => 'fa-ban' }
  end

  def privacy
    @privacy = Empresa
          .select("empresas.privacidad")
          .where("idEmpresa = ?", @sitio[0].idEmpresa)
    if !@privacy || !@privacy[0].privacidad || @privacy[0].privacidad.length <= 1
      redirect_to "/"
      return
    end
  end

  def ayuda
  end

  def personalizar_menu
    get_modulos_usuario
    return redirect_to "/" if @modulos.length == 1 || @bloques.length == 1
    get_modulos_personalizados
  end

  def personalizar_menu_t
    modulo    = params[:modulo] if params.has_key?(:modulo)
    escondido = params[:escondido] if params.has_key?(:escondido)
    return if modulo.nil? || escondido.nil?

    MenuCustomize.where(idUsuario: current_user.id, modulo: modulo).destroy_all
    if escondido.to_i == 0
      MenuCustomize.create(idUsuario: current_user.id, modulo: modulo, escondido: 1).save
    end

    get_modulos_usuario
    return redirect_to "/" if @modulos.length == 1 || @bloques.length == 1
    get_modulos_personalizados
  end

  def zammad_create
    grupo = params[:grupo]     if params.has_key?(:grupo)
    mensaje = params[:mensaje] if params.has_key?(:mensaje)
    archivo = params[:archivo] if params.has_key?(:archivo)

    if !grupo || !mensaje || mensaje.to_s.length < 1
      return redirect_to '/', alert: "Favor de ingresar un mensaje válido"
    end

    nodo_attachment = {}
    if archivo
     file_size = (File.size(archivo.path).to_f / 2**20).round(2)

      # file_size = '%.2f' % (File.size(archivo.path).to_f / 2**20)
      if file_size > 2.1
        return redirect_to '/', alert: "Favor de ingresar un archivo menor que 2 MB"
      end

      data = Base64.encode64(File.read(archivo.path))

      nodo_attachment = {
        attachments: [
          'filename' => archivo.original_filename,
          'data' => data,
          'mime-type' => archivo.content_type,
        ],
      }
    end

    usuario = current_user.name.split("-").join(" ").strip.titleize rescue "Usuario"
    usuario = "#{usuario} <#{current_user.email}>"
    email = current_user.email
    email = "#{email.gsub(" ", "").downcase}@pintacomex.mx" if email.count('@') != 1

    url = 'http://servercampinta.dyndns.org:8088/'
    #url = 'http://localhost:3000/' if !@modo_local

    params = {
      state: 'new',
      group: grupo,
      customer_id: "guess:#{email}",
      title: "Ticket de #{usuario}",
      article: {
        content_type: 'text/plain',
        body: mensaje,
      }.merge(nodo_attachment),
    }

    p "Creando el siguiente ticket en Zammad: #{params.to_s}"

    begin
      client = ZammadAPI::Client.new(
        url:        url,
        http_token: 'r-bWTUiBTewoteaHybYp_Q0_p3kyvguW0d9zoxkZkev5Xf3kWnQzX5DlZmaOKKZP',
      )

      ticket = client.ticket.create(params)

    rescue Exception => exc
      p "Ha habido un error al generar el ticket al conectarse a Zammad: #{exc}"
      return redirect_to '/', alert: "Lo sentimos, ha habido un error al conectarse al sistema de tickets"
    end

    if ticket && ticket.id > 0
      p "Ticket creado exitosamente"
      HomeMailer.email_something_html("#{current_user[:email]}", 'Usted ha creado un Ticket', "<p>Estimado(a) usuario usted acaba de dar de alta un Ticket con nosotros.Para poder ver el estatus del mismo debe seguir los siguientes pasos: <br>Usted debe dar click en el link de abajo, de redireccionará a nuestra página de Tickets donde debe ingresar su usuario en caso de ya haber creado tickets anteriormente, en caso contrario debera dar click en Forgot password?(Contraseña olvidada). Posteriormente ingresara el email con el que dio de alta su ticket. Debera regresar a su email y dar una contraseña y listo!' <br> <a href='http://pintacomex.dyndns.org:8088'>ZAMMAD</a></p>").deliver_now
      return redirect_to '/', notice: "Ticket creado exitosamente. Muy pronto será contactado por un agente"
    else
     p "Ha habido un error al generar el ticket"
     return redirect_to '/', alert: "Lo sentimos, ha habido un error al generar el ticket"
    end

  end

 private

 def get_modo_local
    @modo_local = false
    sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","").gsub("bajapaint","").gsub("pintacomex","")
    @modo_local = true if sending_host == "localhost"
  end

  def get_mimes
    @mimes = ["image/jpg", "image/jpeg", "image/png", "image/gif", "application/pdf", "application/force-download", "application/xls", "application/xlsx", "application/doc", "application/docx", "application/ppt", "application/pptx", "application/zip", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.openxmlformats-officedocument.wordprocessingml.template", "application/vnd.ms-word.document.macroEnabled.12", "application/vnd.ms-word.template.macroEnabled.12", "application/vnd.ms-excel", "application/vnd.ms-excel", "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.openxmlformats-officedocument.spreadsheetml.template", "application/vnd.ms-excel.sheet.macroEnabled.12", "application/vnd.ms-excel.template.macroEnabled.12", "application/vnd.ms-excel.addin.macroEnabled.12", "application/vnd.ms-excel.sheet.binary.macroEnabled.12", "application/vnd.ms-powerpoint", "application/vnd.ms-powerpoint", "application/vnd.ms-powerpoint", "application/vnd.ms-powerpoint", "application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/vnd.openxmlformats-officedocument.presentationml.template", "application/vnd.openxmlformats-officedocument.presentationml.slideshow", "application/vnd.ms-powerpoint.addin.macroEnabled.12", "application/vnd.ms-powerpoint.presentation.macroEnabled.12", "application/vnd.ms-powerpoint.template.macroEnabled.12", "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"].join(",")
  end

  def get_tableros_for_user
    @tiene_tableros = false
    sql = "SELECT TableroUsuarios.* FROM TableroUsuarios WHERE IdUsuario = #{User.sanitize(current_user.id)}"
    @usuario = @dbEsta.connection.select_all(sql).first rescue false
    return unless @usuario
    sql = "SELECT TableroLayout.*, '' as nombre, '' as adicional, '' as url, '' as TipoMedidor FROM TableroLayout WHERE IdLayout = #{User.sanitize(@usuario['IdLayout'])}"
    @elementos = @dbEsta.connection.select_all(sql) rescue []
    @medidores = []
    @elementos.each do |layout|
      layout['nombre'] = get_layout_param(layout, 'NombreElemento')
      layout['adicional'] = get_layout_param(layout, 'TituloAdicional')
      layout['url'] = get_layout_param(layout, 'Url')
      sql = "SELECT TableroMedidores.* FROM TableroMedidores where IdMedidor = #{User.sanitize(layout['IdMedidor'].to_i)} limit 1"
      medidor = @dbEsta.connection.select_all(sql).first rescue false
      if medidor
        @medidores << medidor
        layout['TipoMedidor'] = medidor['TipoMedidor']
      end
    end
    @css_grid = get_css_grid
    @tiene_tableros = true if @medidores.present?
  end

  def get_css_grid
    #// grid.layoutit.com?id=RjNs0yl
    #//   grid-template-areas: "area-1 area-2 area-3 area-4" "area-5 area-5 area-3 area-6" ". . . .";
    grid = [[".", ".",".", "."], [".", ".",".", "."], [".", ".",".", "."], [".", ".",".", "."]]
    @elementos.each do |layout|
      class_name = "medidor-#{layout['IdMedidor']}"
      xini = layout['Xini'] - 1
      yini = layout['Yini'] - 1
      xfin = layout['Xfin'] - 1
      yfin = layout['Yfin'] - 1
      (xini..xfin).each do |x|
        (yini..yfin).each do |y|
          grid[y][x] = class_name if grid[y][x] == "."
        end
      end
    end
    grid.select! { |row|  row != [".", ".",".", "."] }
    "\"#{grid.map{|row| row.join(" ")}.join("\" \"")}\""
  end
end
