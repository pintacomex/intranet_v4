class ComisionesV1Pdf < Prawn::Document
	include ActionView::Helpers::NumberHelper
	include ActionView::Helpers::TextHelper
	def initialize(vendedor, nombre, mes, level, nombre_suc, objetivos, dias_transcurridos, categoria)
		require "prawn/measurement_extensions"
		super(page_size: "LETTER", margin: 1)
		font "Helvetica"
		font_size 12

		fill_color "039be5"
		fill_rectangle [0, 800], 800, 100

		fill_color "b3e5fc"
		fill_rectangle [25, 663], 250, 25

		fill_color "eeeeee"
		fill_rectangle [490, 680], 100, 20
		fill_rectangle [490, 652], 100, 20
		fill_rectangle [490, 622], 100, 20

		box_heigth = 80
		if level == 1 || level == 2
			box_heigth = 160
		end

		fill_color "f5f5f5"
		fill_rectangle [65, 570], 250, box_heigth

		fill_color "b3e5fc"
		fill_rectangle [310, 570], 150, box_heigth

		stroke_color "ffffff"

		stroke do
		 horizontal_line 65, 500, :at => 530
			if level == 1 || level == 2
				horizontal_line 65, 500, :at => 490
				horizontal_line 65, 500, :at => 450
			end
		end
		fill_color "ffffff"

		place_text("Estimación de comisiones por ventas del mes #{mes} de #{vendedor['Mes'][0..3]}",60, 7,18,120,5,'B','C',4)

		fill_color "212121"

		place_text("Nombre:",10,40,12,150,5,'','L',4)


		place_text("#{nombre}",10,45,20,150,5,'','L',4)
		place_text("Num.Empleado: ",10,57,12,150,5,'','L',4)
		place_text("#{ if level == 2 then vendedor['IdEncargado'] elsif level == 1 then vendedor['IdVendedor'] else  vendedor['IdEmpleado'] end }",42,57,12,150,5,'','L',4)
		if level == 3
			place_text("Zona: ",10,65,12,150,5,'','L',4)
			place_text("#{vendedor['Zona']} ",24,65,12,150,5,'','L',4)
			place_text("Subzona: ",10,72,12,150,5,'','L',4)
			place_text("#{vendedor['SubZona']} ",30,72,12,150,5,'','L',4)
		else
			place_text("Sucursal: ",10,65,12,150,5,'','L',4)
			place_text("#{nombre_suc['Num_suc']} - #{nombre_suc['Nombre']}",30,65,12,150,5,'','L',4)
		end

		place_text("Últ.fecha procesada:",20,40,12,150,5,'','R',4)
		if level == 3
			place_text("#{vendedor['UltFechaProcesada'][-2..-1] rescue 0}/#{vendedor['UltFechaProcesada'][4..5] rescue 0}/#{vendedor['UltFechaProcesada'][0..3] rescue 0}",175,40,12,150,5,'','L',4)
		else
			place_text("#{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",175,40,12,150,5,'','L',4)
		end
		place_text("Días con venta:",20,50,12,150,5,'','R',4)
		place_text("#{vendedor['DiasOperados']}",175,50,12,150,5,'','L',4)
		place_text("Días restantes en el mes:",20,60,12,150,5,'','R',4)
		place_text("#{vendedor['DiasPorTranscurrir']}",175,60,12,150,5,'','L',4)
		place_text("#{if vendedor['Categoria'] == 3 then 'Comision por Coordinador'  else '' end}", 140,70,12,150,5,'','L',4)

		#vendedor
		if level == 1
			place_text("Objetivo de ventas del vendedor del mes #{mes} de #{vendedor['Mes'][0..3]}",30,80,11,70,5,'','L',4)
		  place_text("#{number_to_currency(vendedor['ObjNetas'], :locale => :mx, :precision => 2)}",120,85,12,150,5,'','L',4)

			place_text("Objetivo diario de ventas del vendedor al día #{vendedor['ultFechaProcesada'][6..7]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",30,93,11,70,5,'','L',4)
		  place_text("#{number_to_currency(vendedor['ObjNetasAlDia'], :locale => :mx, :precision => 2)}",120,97,12,150,5,'','L',4)

			place_text("Ventas totales del vendedor al #{vendedor['ultFechaProcesada'][6..7]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",30,107,11,70,5,'','L',4)
		  place_text("#{number_to_currency(vendedor['Netas'], :locale => :mx, :precision => 2)}",120,110,12,150,5,'','L',4)

			place_text("Cumplimiento de objetivo de ventas del vendedor al #{vendedor['ultFechaProcesada'][6..7]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",30,122,11,70,5,'','L',4)
		  place_text("#{vendedor['OpaNetas']} %",120,125,12,150,5,'','L',4)
		#Sucursal
		elsif level == 2
			place_text("Objetivo de ventas de la sucursal del mes #{mes} de #{vendedor['Mes'][0..3]}",30,80,11,70,5,'','L',4)
		  place_text("#{number_to_currency(vendedor['ObjNetas'], :locale => :mx, :precision => 2)}",120,85,12,150,5,'','L',4)

			place_text("Objetivo de ventas de la sucursal al día #{vendedor['ultFechaProcesada'][6..7]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",30,93,11,70,5,'','L',4)
		  place_text("#{number_to_currency(vendedor['ObjNetasAlDia'], :locale => :mx, :precision => 2)}",120,97,12,150,5,'','L',4)

			place_text("Ventas totales de la sucursal al #{vendedor['ultFechaProcesada'][6..7]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",30,107,11,70,5,'','L',4)
		  place_text("#{number_to_currency(vendedor['Netas'], :locale => :mx, :precision => 2)}",120,110,12,150,5,'','L',4)

			place_text("Cumplimiento de objetivo de ventas de la sucursal al #{vendedor['ultFechaProcesada'][6..7]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",30,122,11,70,5,'','L',4)
		  place_text("#{vendedor['OpaNetas']} %",120,125,12,150,5,'','L',4)
		else
			#Regional
			place_text("Alcance #{vendedor['DiasPorTranscurrir']  > 0 ? 'proyectado' : ''} de objetivo de ventas de la #{if level == 3 then 'zona' else 'sucursal' end}",30,80,11,70,5,'','L',4)
			place_text("#{if level == 2 then vendedor['OpaNetas'] elsif level == 1 then vendedor['OpaSucNetas'] else vendedor['OpaNetas'] end} %",120,85,12,150,5,'','L',4)
			place_text("Ventas proporcionales proyectadas de la #{if level == 3 then 'zona' else 'sucursal' end} para la comisiòn de Obj. de Suc.",30,94.5,11,80,5,'','L',4)
			place_text("#{if level == 2 then number_to_currency(vendedor['SucContadoProyectada'].to_f + vendedor['CobranzaProyectada'], :locale => :mx, :precision => 2) elsif level == 1 then number_to_currency(vendedor['BaseComiSucNetas'] * (vendedor['FactorDeAsignacion']/100), :locale => :mx, :precision => 2) else number_to_currency(vendedor['ContadoProyectada'].to_f + vendedor['CobranzaProyectada'], :locale => :mx, :precision => 2) end}",120,97.5,12,100,5,'','L',4)
		end

		place_text("Alcances registrados en el mes",75,150,15,70,5,'B','C',4)

		array_vendedor = []

		move_down 470
		if level == 3
			total_comision = vendedor['ComisSucNetas'].to_f + vendedor['ComisNetas'].to_f + vendedor['ComisAxT'].to_f + vendedor['ComisTP'].to_f + vendedor['ComisNT'].to_f + vendedor['ComisNetasExOp'].to_f + vendedor['ComisRentabilidad'].to_f + vendedor['ComisCxC'].to_f
		elsif level == 1
			total_comision = vendedor['ComisSucNetas'].to_f + vendedor['ComisNetas'].to_f + vendedor['ComisAxT'].to_f + vendedor['ComisTP'].to_f + vendedor['ComisNT'].to_f + vendedor['ComisNetasExOp'].to_f + vendedor['ComisCubreEncargado'].to_f
			if vendedor['ComisCubreEncargado'].to_f > 0
				array_vendedor = [ ["Meta", "Objetivo diario al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}", "Alcance real al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}", "% de proyectado al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}", 	"Porcentaje", "Comisión al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}"],
					["Obj. proporcional de sucursal","",	"#{number_to_currency(vendedor['BaseComiSucNetas'], :locale => :mx, :precision => 2)}",	"#{vendedor['OpaSucNetas']} %",	"#{vendedor['PorcComisSucNetas']}%",	"#{number_to_currency(vendedor['ComisSucNetas'], :locale => :mx, :precision => 2)}"],
					["Excelencia Operativa", "", "", "#{vendedor['CalifExcelenciaOp'].to_f >= 10.0 ? "SI" : "NO"}", "#{vendedor['PorcComisNetasExOp']}%", "#{number_to_currency(vendedor['ComisNetasExOp'], :locale => :mx, :precision => 2)}"],
					["Ventas netas del vendedor",	"#{number_to_currency(vendedor['ObjNetasAlDia'], :locale => :mx, :precision => 2)}",	"#{number_to_currency(vendedor['Netas'], :locale => :mx, :precision => 2)}",			"#{vendedor['OpaNetas']} %","#{vendedor['PorcComisNetas']}%","#{number_to_currency(vendedor['ComisNetas'], :locale => :mx, :precision => 2)}"],
					["Artículos por ticket", "#{vendedor['ObjAxT']}","#{vendedor['AxT']}","#{vendedor['OpaAxT']} %","#{vendedor['PorcComisAxT']}%", "#{number_to_currency(vendedor['ComisAxT'], :locale => :mx, :precision => 2)}"],
					["Ticket promedio","#{number_to_currency(vendedor['ObjTP'], :locale => :mx, :precision => 2)}",	"#{number_to_currency(vendedor['TP'], :locale => :mx, :precision => 2)}",				"#{vendedor['OpaTP']} %","#{vendedor['PorcComisTP']}%", "#{number_to_currency(vendedor['ComisTP'], :locale => :mx, :precision => 2)}"],
					["Número de transacciones","#{vendedor['ObjNTAlDia']}",	"#{vendedor['NT']}","#{vendedor['OpaNT']} %","#{vendedor['PorcComisNT']}%","#{number_to_currency(vendedor['ComisNT'], :locale => :mx, :precision => 2)}"],
					["Comisión por cubrir encargado","",	"#{dias_transcurridos['DiasTranscurridos']} Dias Transcurridos", "", "","#{number_to_currency(vendedor['ComisCubreEncargado'], :locale => :mx, :precision => 2)}"],
					["Comisión estimada al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",	"","","","","#{number_to_currency(total_comision, :locale => :mx, :precision => 2)}"]
			 	]
			else
				array_vendedor = [ ["Meta", "Objetivo diario al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}", "Alcance real al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}", "% de proyectado al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}", 	"Porcentaje", "Comisión al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}"],
					["Obj. proporcional de sucursal", "",	"#{number_to_currency(vendedor['BaseComiSucNetas'], :locale => :mx, :precision => 2)}",	"#{vendedor['OpaSucNetas']} %",	"#{vendedor['PorcComisSucNetas']}%",	"#{number_to_currency(vendedor['ComisSucNetas'], :locale => :mx, :precision => 2)}"],
					["Excelencia Operativa", "", "", "#{vendedor['CalifExcelenciaOp'].to_f >= 10.0 ? "SI" : "NO"}", "#{vendedor['PorcComisNetasExOp']}%", "#{number_to_currency(vendedor['ComisNetasExOp'], :locale => :mx, :precision => 2)}"],
					["Ventas netas del vendedor",	"#{number_to_currency(vendedor['ObjNetasAlDia'], :locale => :mx, :precision => 2)}",	"#{number_to_currency(vendedor['Netas'], :locale => :mx, :precision => 2)}",			" #{vendedor['OpaNetas']} %","#{vendedor['PorcComisNetas']}%","#{number_to_currency(vendedor['ComisNetas'], :locale => :mx, :precision => 2)}"],
					["Artículos por ticket", "#{vendedor['ObjAxT']}","#{vendedor['AxT']}","#{vendedor['OpaAxT']} %","#{vendedor['PorcComisAxT']}%", "#{number_to_currency(vendedor['ComisAxT'], :locale => :mx, :precision => 2)}"],
					["Ticket promedio","#{number_to_currency(vendedor['ObjTP'], :locale => :mx, :precision => 2)}",	"#{number_to_currency(vendedor['TP'], :locale => :mx, :precision => 2)}",				"#{vendedor['OpaTP']} %","#{vendedor['PorcComisTP']}%", "#{number_to_currency(vendedor['ComisTP'], :locale => :mx, :precision => 2)}"],
					["Número de transacciones","#{vendedor['ObjNTAlDia']}",	"#{vendedor['NT']}","#{vendedor['OpaNT']} %","#{vendedor['PorcComisNT']}%","#{number_to_currency(vendedor['ComisNT'], :locale => :mx, :precision => 2)}"],
					["Comisión estimada al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",	"","","","","#{number_to_currency(total_comision, :locale => :mx, :precision => 2)}"]
			 	]
			end
		else
			total_comision = vendedor['ComisSucNetas'].to_f + vendedor['ComisNetas'].to_f + vendedor['ComisAxT'].to_f + vendedor['ComisTP'].to_f + vendedor['ComisNT'].to_f + vendedor['ComisNetasExOp'].to_f
		end
		if level == 2
			table_array = [ ["Meta","Objetivo diario al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}","Alcance real al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}","% De cumplimiento al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}","Porcentaje","Comisión al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}"],
				["Obj. proporcional de sucursal","#{number_to_currency(vendedor['ObjNetasAlDia'], :locale => :mx, :precision => 2) }","#{number_to_currency(vendedor['Netas'], :locale => :mx, :precision => 2) }","#{  vendedor['OpaNetas']} %","#{ categoria == 5 ? (vendedor['ComisNetas']/vendedor['Netas']).round(4) : vendedor['PorcComisNetas']}%",	"#{number_to_currency(vendedor['ComisNetas'], :locale => :mx, :precision => 2)}"],
				["Excelencia Operativa", "", "", "#{vendedor['CalifExcelenciaOp'].to_f > 0 ? "SI" : "NO"}", "#{vendedor['PorcComisNetasExOp']}%", "#{number_to_currency(vendedor['ComisNetasExOp'], :locale => :mx, :precision => 2)}"],
				["Artículos por ticket","#{objetivos['ObjAxT'] }",	"#{vendedor['AxT']}",			"#{vendedor['OpaAxT']} %","#{categoria == 5 ? (vendedor['ComisAxT']/vendedor['Netas']).round(4) : vendedor['PorcComisAxT']}%", "#{number_to_currency(vendedor['ComisAxT'], :locale => :mx, :precision => 2)}"],
				["Ticket promedio","#{number_to_currency(objetivos['ObjTP'], :locale => :mx, :precision => 2)}",	"#{number_to_currency(vendedor['TP'], :locale => :mx, :precision => 2)}","#{vendedor['OpaTP']} %","#{categoria == 5 ? (vendedor['ComisTP']/vendedor['Netas']).round(4) : vendedor['PorcComisTP']}%", "#{number_to_currency(vendedor['ComisTP'], :locale => :mx, :precision => 2)}"],
				["Número de transacciones","#{objetivos['ObjNT'] }",	"#{vendedor['NT']}","#{vendedor['OpaNT']} %","#{categoria == 5 ? (vendedor['ComisNT']/vendedor['Netas']).round(4) : vendedor['PorcComisNT']}%","#{number_to_currency(vendedor['ComisNT'], :locale => :mx, :precision => 2)}"],
				["Comisión estimada al #{vendedor['ultFechaProcesada'][-2..-1]}/#{vendedor['ultFechaProcesada'][4..5]}/#{vendedor['ultFechaProcesada'][0..3]}",	"","","","","#{number_to_currency(total_comision, :locale => :mx, :precision => 2)}"]
		 ]

		elsif level == 1
			table_array = array_vendedor
		else
			table_array = [ ["Meta","Objetivo","Alcance obtenido","Alcance #{vendedor['DiasPorTranscurrir']  > 0 ? 'proyectado' : ''}","Porcentaje","Comisión #{vendedor['DiasPorTranscurrir']  > 0 ? 'proyectada' : ''}"],
				["Objetivo de zona","#{number_to_currency(vendedor['ObjNetas'], :locale => :mx, :precision => 2) }","#{number_to_currency(vendedor['Netas'], :locale => :mx, :precision => 2) }","#{  vendedor['OpaNetas']} %","#{ vendedor['PorcComisNetas']}%",	"#{number_to_currency(vendedor['ComisNetas'], :locale => :mx, :precision => 2)}"],
				["Excelencia Operativa", "", "", "#{vendedor['CalifExcelenciaOp'].to_f > 0 ? "SI" : "NO"}", "#{vendedor['PorcComisNetasExOp']}%", "#{number_to_currency(vendedor['ComisNetasExOp'], :locale => :mx, :precision => 2)}"],
				["Artículos por ticket","#{vendedor['ObjAxT'] }",	"#{vendedor['AxT']}",			"#{vendedor['OpaAxT']} %","#{vendedor['PorcComisAxT']}%", "#{number_to_currency(vendedor['ComisAxT'], :locale => :mx, :precision => 2)}"],
				["Ticket promedio","#{number_to_currency(vendedor['ObjTP'], :locale => :mx, :precision => 2)}",	"#{number_to_currency(vendedor['TP'], :locale => :mx, :precision => 2)}","#{vendedor['OpaTP']} %","#{vendedor['PorcComisTP']}%", "#{number_to_currency(vendedor['ComisTP'], :locale => :mx, :precision => 2)}"],
				["Número de transacciones","#{vendedor['ObjNT'] }",	"#{vendedor['NT']}","#{vendedor['OpaNT']} %","#{vendedor['PorcComisNT']}%","#{number_to_currency(vendedor['ComisNT'], :locale => :mx, :precision => 2)}"],
				["Rentabilidad","",	"#{number_to_currency(vendedor['Rentabilidad'], :locale => :mx, :precision => 2)}","#{vendedor['OpaRentabilidad']} %","#{vendedor['PorcComisRentabilidad']}%","#{number_to_currency(vendedor['ComisRentabilidad'], :locale => :mx, :precision => 2)}"],
				["Cuentas por Cobrar","","","#{vendedor['CalifCxC']}%","#{vendedor['PorcComisCxC']}%","#{number_to_currency(vendedor['ComisCxC'], :locale => :mx, :precision => 2)}"],
				["Comisión total #{vendedor['DiasPorTranscurrir']  > 0 ? 'proyectada' : ''}",	"","","","","#{number_to_currency(total_comision, :locale => :mx, :precision => 2)}"]
		 ]
		end

		bold = 6
		bold = 7 if table_array.length == 8
		bold = 8 if level == 3
		bold = 8 if level == 1 && vendedor['ComisCubreEncargado'].to_f > 0
		table(table_array, :row_colors => ["ffffff"],:position => :center, :cell_style => {:size => 9,:background_color => "f5f5f5", :border_color => "ffffff"})do
		  row(0).font_style = :bold
		  row(0).align = :center
		  column(0..7).width = 90
		  row(bold).column(5).size = 16
		end

		place_image('logo_pintacomex',5,3,50,25)

		place_text("- Los datos mostrados en esta hoja ùnicamente muestran los alcances teòricos a los que se puede llegar al finalizar el mes, mismos que se iran modificando cada dìa con base a los datos de las ventas reales, y proyectando los dìas futuros en que aùn es posible hacer ventas.\n- El alcance proyectado es el que se puede obtener al fin del mes si se continùa vendiendo con la misma tendencia en los dìas del mes que restan.\n- La comisiòn proyectada es la que se puede obtener al fin del mes si las ventas de la sucursal y del vendedor se mantienen con la misma tendencia durante los dìas del mes que restan.\n- La comisiòn proyectada es informativa, y serà diferente de la comisiòn real alcanzada al final del mes.",10,250,7,200,5,'B','L',4)
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
			image "public/images_nomina/#{img}.png", at: [x.send(:mm), [790-y.send(:mm)]], width: w.send(:mm), heigth: h.send(:mm)
		end

		def fix_ref(ref)
      nref = ref.gsub(" ", "").gsub("-", "").gsub("/", "")
			return ref if nref.length != 16
			nref = "#{nref[0..3]}-#{nref[4..7]}-#{nref[8..11]}-#{nref[12..15]}"
			return nref
		end
end
