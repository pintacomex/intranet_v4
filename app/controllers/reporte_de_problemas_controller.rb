class ReporteDeProblemasController < InheritedResources::Base

  before_filter :only_admins, :except => [:new, :create]

  def index
    @reporte_de_problemas = ReporteDeProblema.select("reporte_de_problemas.*,sitios.nombreWeb").joins("left join sitios on reporte_de_problemas.sitio = sitios.id").order("id DESC").page params[:page]
  end

  def show
    @reporte_de_problema = ReporteDeProblema
      .select("reporte_de_problemas.*,sitios.nombreWeb")
      .joins("left join sitios on reporte_de_problemas.sitio = sitios.id")
      .where("reporte_de_problemas.id = ?", params[:id]).first
  end

  def create
    @reporte_de_problema = ReporteDeProblema.new(params[:reporte_de_problema])

    @reporte_de_problema.sitio = @sitio[0].id

    respond_to do |format|
      if @reporte_de_problema.save
      	# Manda mail de reporte
      	if mail_reporte
	        format.html { redirect_to '/users/sign_in', notice: 'Gracias por su reporte. Nos pondremos en contacto con usted tan pronto sea posible.' }
    	    format.json { render json: @reporte_de_problema, status: :created, location: @reporte_de_problema }
    	  else
    		  # Ya se ha relizado el redirect
    		  return
    	  end
      else
        format.html { render action: "new" }
        format.json { render json: @reporte_de_problema.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  	def only_admins
  	  # Esto deberia poder hacerse en una linea
      if !user_signed_in?
      	return redirect_to '/'
      end
      if !current_user.has_role? :admin
      	return redirect_to '/'
      end
  	end

  	def mail_reporte
  	  body = "Hola. Se ha creado el reporte de un problema en el sitio.\n\n Sitio:\t#{@sitio[0].nombre}\n Nombre:\t#{@reporte_de_problema.nombre}\n Email:\t#{@reporte_de_problema.email}\n Ciudad:\t#{@reporte_de_problema.ciudad}\n Descripcion:\t#{@reporte_de_problema.descripcion}"

      # mail = JustMailer.email_something("fernandoc@pintacomex.mx", 'Reporte de Problema', body)
      # return true
      # mail = JustMailer.email_something("soporte@pintacomex.freshdesk.com;repfacturas@#{@sitio[0].nombreWeb}.com.mx", 'Reporte de Problema', body)
      mail_to = IntParam.where("nombre_param = 'mail_reporte_problema'").first.valor_param rescue "fernandoc@pintacomex.mx"

      mail = JustMailer.email_something(mail_to, 'Reporte de Problema', body)

      begin
        if mail.deliver
          return true
        else
          redirect_to '/users/sign_in', notice: 'Gracias por su reporte. Nos pondremos en contacto con usted tan pronto sea posible.' 
          return false
        end            
      rescue
          redirect_to '/users/sign_in', notice: 'Gracias por su reporte. Nos pondremos en contacto con usted tan pronto sea posible.' 
          return false
      end    
  	end

    def reporte_de_problema_params
      params.require(:reporte_de_problema).permit(:sitio, :nombre, :email, :ciudad, :descripcion)
    end
end

