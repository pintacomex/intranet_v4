class Tableros::UsuariosController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :find_usuario, only: [:edit, :update, :show, :destroy]
  before_filter :obtiene_catalogos, only: [:new, :create, :edit, :update]

  def index
    sql = "SELECT TableroUsuarios.*, '' as NombreUsuario FROM TableroUsuarios ORDER BY IdUsuario, IdLayout"
    @usuarios = @dbEsta.connection.select_all(sql)
    @usuarios.each do |a|
      if a['IdUsuario'].to_i > 0
        u = User.where("id = #{User.sanitize(a['IdUsuario'])}").first
        a['NombreUsuario']  = u.name rescue ''
      end
    end
  end

  def new
    @new = true
    @usuario = {}
    @usuario['IdUsuario'] = 1
    @usuario['IdLayout'] = 1
  end

  def edit
    @new = false
  end

  def create
    create_or_update
  end

  def update
    create_or_update
  end

  def show
  end

  def destroy
    sql = "DELETE FROM TableroUsuarios WHERE IdUsuario = #{User.sanitize(@id.first)} AND IdLayout = #{User.sanitize(@id.last)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      redirect_to "/tableros/usuarios", alert: "No se ha podido borrar el usuario. Error: #{exc.message}"
    end
    redirect_to "/tableros/usuarios", notice: "Usuario borrado exitosamente"
  end

  private

    def find_usuario
      @id = params[:id].to_s.split("-")
      sql = "SELECT TableroUsuarios.*, '' as NombreUsuario FROM TableroUsuarios WHERE IdUsuario = #{User.sanitize(@id.first)} AND IdLayout = #{User.sanitize(@id.last)} LIMIT 1"
      @usuario = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/' unless @usuario
      if @usuario['IdUsuario'].to_i > 0
        u = User.where("id = #{User.sanitize(@usuario['IdUsuario'])}").first
        @usuario['NombreUsuario'] = u.name rescue 'Usuario No Encontrado'
      end
    end

    def obtiene_catalogos
      @usuarios = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["#{u.name.to_s.gsub(" - ", " ")}", "#{u.id}"]}.uniq
      @layouts = @dbEsta.connection.select_all("SELECT TableroLayout.* FROM TableroLayout GROUP BY IdLayout ORDER BY IdLayout, IdElemento").map{|u| ["#{u['IdLayout']} - #{u['NombreElemento'].to_s.truncate(20)}", "#{u['IdLayout']}"]}.uniq
    end

    def create_or_update
      @new = params[:new] == "true"
      @id_usuario = params[:idusuario].to_i
      @id_layout = params[:idlayout].to_i
      @usuario = {}
      @usuario['IdUsuario'] = @id_usuario
      @usuario['IdLayout'] = @id_layout
      sql = "INSERT INTO TableroUsuarios (IdUsuario, IdLayout) VALUES ( #{User.sanitize(@id_usuario)}, #{User.sanitize(@id_layout)} ) ON DUPLICATE KEY UPDATE IdUsuario = #{User.sanitize(@id_usuario)}, IdLayout = #{User.sanitize(@id_layout)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        flash[:alert] = "No se ha podido #{@new ? "crear" : "editar"} el usuario. Error: #{exc.message}"
        return render 'edit'
      end
      redirect_to "/tableros/usuarios/#{@id_usuario}-#{@id_layout}", notice: "Usuario #{@new ? "creado" : "editado"} exitosamente"
    end
end

