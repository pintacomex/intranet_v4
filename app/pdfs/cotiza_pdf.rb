#!/bin/env ruby
# encoding: utf-8
class CotizaPdf < Prawn::Document
	include ActionView::Helpers::NumberHelper
	include ActionView::Helpers::TextHelper

	def initialize(hcotiza, dcotiza, succotiza, clicotiza, empcotiza, datoscotiza, catsuc, ivatxt, status)
		require "prawn/measurement_extensions"
		super(page_size: "LETTER", margin: 1)
		font "Helvetica"
		font_size 12

    sucNombre = succotiza['SucNombre']
    sucTel = succotiza['SucTel']


    sucDir1 = "#{succotiza['SucCalle']} #{succotiza['SucNumExt']} #{succotiza['SucNumInt']}"
    sucDir2 = "#{succotiza['SucColonia']}"
    sucDir3 = "#{succotiza['SucLoc']}, #{succotiza['SucEstado']}"
		codigoPostal = "#{succotiza['SucCP']}"

    if sucDir1.length < 25
      sucDir1 = "#{sucDir1} CP #{codigoPostal}"
    else
      sucDir2 = "#{sucDir2} CP #{codigoPostal}"
    end

    empNombre = empcotiza['RazonSocial']
    empRFC    = empcotiza['Rfc']
    empDir1   = empcotiza['Calle']
    empDir2   = empcotiza['Colonia']
    empDir3   = "CP #{empcotiza['CodigoPostal']}"
    empDir4   = "#{empcotiza['DelegMunic']} #{empcotiza['Estado']}"

    regimen = "Regimen"

#Datos del Cliente
		razonSocial = clicotiza['Nombre']
		rfc         = clicotiza['Rfc']
		calle       = clicotiza['Callenum']
		numExt      = clicotiza['NumExt']
		numInt      = clicotiza['NumInt']
		colonia     = clicotiza['Colonia']
		cp     		  = clicotiza['Cp']
		cd_del_mun  = clicotiza['Delemuni']
		estado      = clicotiza['NomEstado']
		contacto    = clicotiza['Contacto']

		place_image('logo',11,7.5,47.92,10.58)
    place_image('Cotizacion',167,9.4,38.69,23.79)
    place_image('Bottom',7.9,200.2,199.81,82.91)
    place_image('BarraTop',7.5,67.2,199.31,5.59)
    place_image('Cantidad',8.5,171.5,152.23,12.78)
    if hcotiza['Descfac'].to_f > 0
			if hcotiza['Ivafac'].to_f > 0
				place_image('Totales_Desc',163.2,171.2,42.93,27.52)
			else
				place_image('Totales_Desc_SRfc',163.2,171.2,42.93,27.52)
			end
		else 
			if hcotiza['Ivafac'].to_f > 0
				place_image('Totales_Iva',163.2,171.2,42.93,27.52)
			else
				place_image('Totales',163.2,171.2,42.93,27.52)
			end
		end


#Datos de la Sucursal
#		place_text("Expedido en:",11,18.5,7,52,3,"","C")
  	place_text("#{sucNombre}\n#{sucDir1}\n#{sucDir2}\n#{sucDir3}",3,18.5,7,68,3.2,"","C")

#Datos de la Empresa
  	place_text("#{empNombre}",69,9.5,14,60,3,"B","C")
		place_text("RFC: #{empRFC}\n#{empDir1}\n#{empDir2}\n#{empDir3}\n#{empDir4}",68,15,8,60,3.5,"","C")

#Datos de la Cotizacion
		place_text("#{hcotiza['Fecha'][6..7]}/#{hcotiza['Fecha'][4..5]}/#{hcotiza['Fecha'][0..3]}",181,15.2,7.5,40,4,'','',2.5)
		if status == "t"
			place_text("#{'%03d' % hcotiza['Sucursal']}-#{'%03d' % hcotiza['IdVendedor']}-#{'%05d' % datoscotiza['NumCotiza']}",181,20.8,7.5,40,4,'','',2.5)
		else
			place_text("Previo",181,20.8,7.5,40,4,'','',2.5)
		end

#Datos delCliente
    place_text("#{razonSocial}",11,33.7,7,170,4.9,'','')
		place_text("#{calle} #{numExt} #{numInt}, #{colonia}\nC.P. #{cp}, #{cd_del_mun}, #{estado}",11,37,7,100,3.9,"","")

#Nota Superior
		place_text("AT'N : ",11,46,8,52,3,"B","")
  	place_text(datoscotiza['Contacto'].to_s,20,46,8,197,2.9,'B','')
  	place_text(datoscotiza['NotaSup'].to_s,11,53.5,7,197,2.9,'','')

#Totales
    suma = hcotiza['Subtotfac'].to_f
    desc  = hcotiza['Descfac'].to_f
    subTotal = hcotiza['Subtotfac'].to_f - hcotiza['Descfac'].to_f
		iva      = hcotiza['Ivafac'].to_f
    total    = hcotiza['Total'].to_f

    ivaporce = "#{ivatxt} %"
    if hcotiza['Descfac'].to_f > 0
			if hcotiza['Ivafac'].to_f > 0
	    	place_text(ivaporce,173.5,189.6,10,30,4.4,'B','')
	    	txt = "#{number_to_currency(suma, :locale => :mx, :precision => 2)}\n#{number_to_currency(desc, :locale => :mx, :precision => 2)}\n#{number_to_currency(subTotal, :locale => :mx, :precision => 2)}\n#{number_to_currency(iva, :locale => :mx, :precision => 2)}\n#{number_to_currency(total, :locale => :mx, :precision => 2)}"
	    	place_text(txt,155,177,10,50,4.4,'','R')
	    else
	    	txt = "#{number_to_currency(suma, :locale => :mx, :precision => 2)}\n#{number_to_currency(desc, :locale => :mx, :precision => 2)}\n#{number_to_currency(total, :locale => :mx, :precision => 2)}"
	    	place_text(txt,155,177,10,50,4.4,'','R')
	    end
		else 
			if hcotiza['Ivafac'].to_f > 0
	    	place_text(ivaporce,173.5,182.7,10,30,4.4,'B','')
	    	txt = "#{number_to_currency(subTotal, :locale => :mx, :precision => 2)}"
	    	place_text(txt,155,178,10,50,4.4,'','R')
	    	txt = "#{number_to_currency(iva, :locale => :mx, :precision => 2)}"
	    	place_text(txt,155,182.7,10,50,4.4,'','R')
	    	txt = "#{number_to_currency(total, :locale => :mx, :precision => 2)}"
	    	place_text(txt,155,187.3,10,50,4.4,'','R')
			else
	    	txt = "#{number_to_currency(total, :locale => :mx, :precision => 2)}"
	    	place_text(txt,155,179.2,10,50,4.4,'','R')
			end
		end

#    if hcotiza['Ivafac'].to_f != 0
#	    txt = "16 %"
#    	place_text(txt,173.5,189.6,10,30,4.4,'B','')
#    	txt = "#{number_to_currency(suma, :locale => :mx, :precision => 2)}\n#{number_to_currency(desc, :locale => :mx, :precision => 2)}\n#{number_to_currency(subTotal, :locale => :mx, :precision => 2)}\n#{number_to_currency(iva, :locale => :mx, :precision => 2)}\n#{number_to_currency(total, :locale => :mx, :precision => 2)}"
#    	place_text(txt,155,177,10,50,4.4,'','R')
#    end

  	totalLetra = "#{(total.to_f).to_words.upcase} PESOS #{((total.to_f).to_s.split(".")[1] || 0).ljust(2,'0')}/100 M.N."
  	place_text("#{totalLetra}",11,178.3,8,140,4.9,'','')

#Detalle
    i    = 0
    irow = 0

    dcotiza.each do |s| 

      y = 73.5 + (i * 4)
			cantidad = s['Cantidad'].to_f 
			unidad   = s['UMedida'].to_s 
			descrip  = s['Descrip'].to_s 
			pUnit    = s['Preunifac'].to_f 
			porcDesc = s['Pordesfac'].to_f 
			subTotal = s['Totrenfac'].to_f 

			if cantidad != 0
				txt = cantidad.to_s
        txt = txt.to_i.to_s if txt[-2,2] == ".0"
        place_text(txt,9,y,8,11,2,'','C')
        place_text("#{unidad}",20,y,8,25,5,'','L') if unidad != ""
	    end
      place_text("#{number_to_currency(pUnit, :locale => :mx, :precision => 2)}",125,y,8,28,5,'','R') if pUnit != 0
      place_text("#{porcDesc}%",153,y,8,23,5,'','R') if porcDesc != 0
	    place_text("#{number_to_currency(subTotal, :locale => :mx, :precision => 2)}",176,y,8,28,5,'','R') if subTotal != 0

	    irow = irow + 1
	    if descrip.length <= 60
      	place_text("#{descrip}",35,y,8,100,5,'','') if descrip != ""
	    	i = i + 1
      elsif descrip.length > 60
        	# La descripcion debe ser de varias lineas, por lo que deben separarse
					descrip = word_wrap(descrip, line_width: 60).split("\n")
        	# descrip.split('').each_slice(40).map {|s| s.join('')}.each do |minidesc|
        	descrip.each do |minidesc|
        	place_text("#{minidesc}",35,y,8,90,5,'','') if minidesc != ""
			    i = i + 1
	        y = 73.5 + (i * 4)
      	end
      end
		end
  	place_rectangle("334AA8",8,71.3,198,2+(i*4))

#Nota Inferior
  	place_text("CONDICIONES COMERCIALES:",11,195,10,197,2.9,'','')
#  	place_text(datoscotiza['Vigencia'].to_s,27.3,203.5,7,3,2.9,'','R')
		if datoscotiza['Vigencia'].to_i == 0
	  	textoinf = "Precios en pesos mexicanos
	  	Precios sujetos a cambio sin previo aviso."
		elsif datoscotiza['Vigencia'].to_i == 1
	  	textoinf = "Precios en pesos mexicanos
	  	Vigencia de la presente cotización : #{datoscotiza['Vigencia'].to_i} dia."
		else
	  	textoinf = "Precios en pesos mexicanos
	  	Vigencia de la presente cotización : #{datoscotiza['Vigencia'].to_i} dias."
	  end
  	place_text(textoinf,11,200.5,7,197,2.9,'','')
  	place_text(datoscotiza['NotaInf'].to_s,11,206.1,7,197,2.9,'','')


#Datos del Vendedor
  	place_text(datoscotiza['DatosVend'].to_s,11,258,7,197,2.9,'','')

	end

	private

		def place_rectangle(color,x,y,w,h)
		    stroke_color color
	    	stroke do
				rounded_rectangle [x.send(:mm),786-y.send(:mm)],w.send(:mm),h.send(:mm), 1
			end
		end

		def place_text(txt,x,y,fs,w,h,sty,ali,leading=0)
			style = :normal
			style = :bold   if sty == "B"
			align = :left
			align = :center if ali == "C"
			align = :right  if ali == "R"
			formatted_text_box [ text: txt, styles: [style] ], at: [x.send(:mm),786-y.send(:mm)], size: fs, width: w.send(:mm), heigth: h.send(:mm), align: align, leading: leading
		end

		def place_image(img,x,y,w,h)
			image "public/images_cotiza/#{img}.png", at: [x.send(:mm), [790-y.send(:mm)]], width: w.send(:mm), heigth: h.send(:mm)
		end
end
