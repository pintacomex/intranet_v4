module ApplicationHelper

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  def fix_show_date(d)
    d = "#{d[0..3]}-#{d[4..5]}-#{d[6..7]}" if d.to_s.length == 8
    return d
  end

  def fix_show_date_int(d)
    d = d.to_s.split(".").first
    d = "#{d[0..3]}-#{d[4..5]}-#{d[6..7]}" if d.to_s.length == 8
    d
  end

  def fix_show_date_mes(d)
    # d = "#{d[0..3]}-#{d[4..5]}" if d.to_s.length == 6 and d.to_s[0..1] == "20"
    return d
  end

  def gen_filtros(index_actual, filtro)
    ans = ""
    (1..9).each do |i|
      break if @titulo_filtros[i].nil?
      if index_actual == i
        ans = "#{ans}&f#{i}=#{filtro['id']}"
      else
        ans = "#{ans}&f#{i}=#{@seleccion_filtros[i]}"
      end
    end
    ans
  end

  def fix_num_to_money(d)
    if d.to_s.to_i.abs() > 0
      return number_to_currency(d, :locale => :mx, :precision => 2)
    end
    d
  end

  def get_footer
    return IntParam.where("nombre_param = 'footer'").first.valor_param rescue ""
  end

  def despliega_grafica(tipo_g, props_g)
    html = ""
    if tipo_g == "morris_bar"
      # <%= despliega_grafica( "morris_bar", { datos: @antsaldos_graph, xkey: "Sucursal", ykeys: ["Saldo"], labels: ["Saldo", "Series B"] } ) %>
      datos  = props_g[:datos]  rescue []
      xkey   = props_g[:xkey]   rescue nil
      ykeys  = props_g[:ykeys]  rescue [nil]
      labels = props_g[:labels] rescue [nil]
      div_id = ('a'..'z').to_a.shuffle[0,8].join
      html = <<-HTML
        <script src="http://cdnjs.cloudflare.com/ajax/libs/raphael/2.1.0/raphael-min.js"></script>
        <script src="http://cdn.oesmith.co.uk/morris-0.4.1.min.js"></script>
        <div id="#{div_id}"></div>
        <script>
          Morris.Bar({
            element: '#{div_id}',
            data: #{datos.to_json},
            xkey: #{xkey.to_json},
            ykeys: #{ykeys.to_json},
            labels: #{labels.to_json}
          });
        </script>
      HTML
    elsif tipo_g == "highcharts_stock"
      # <%= despliega_grafica( "highcharts_stock", { datos: @ventasd, labels: [ @sucursales ] } ) %>
      datos  = props_g[:datos]  rescue []
      # Como las graficas aceptan solo timestamps * 1000, se convierten las fechas
      datos.each do |d|
        d['data'].each do |dd|
          break if dd[0].to_i > 20990000
          dd[0] = Date.parse(dd[0]).to_time.to_i * 1000 if dd[0].to_i < 20990000
        end
      end
      labels = props_g[:labels] rescue [nil]
      div_id = ('a'..'z').to_a.shuffle[0,8].join
      html = <<-HTML
        <script src="http://code.highcharts.com/stock/highstock.js"></script>
        <script src="http://code.highcharts.com/stock/modules/exporting.js"></script>
        <div id="#{div_id}" style="min-height: 400px; min-width: 310px"></div>
        <script>
        $(function () {
            var seriesOptions = [],
                seriesCounter = 0,
                names = #{labels.map{|s| s.to_s}.to_json},
                createChart = function () {
                    $('##{div_id}').highcharts('StockChart', {
                        rangeSelector: {
                            selected: 4
                        },
                        xAxis: {
                            minTickInterval: 24 * 3600 * 1000 * 30,
                            labels: {
                                formatter: function () {
                                  return Highcharts.dateFormat('%m %Y', this.value);
                                    // return (this.value > 0 ? ' + ' : '') + this.value + '%';
                                }
                            }
                        },
                        yAxis: {
                            // labels: {
                            //     formatter: function () {
                            //         return (this.value > 0 ? ' + ' : '') + this.value + '%';
                            //     }
                            // },
                            plotLines: [{
                                value: 0,
                                width: 2,
                                color: 'silver'
                            }]
                        },
                        // plotOptions: {
                        //     series: {
                        //         compare: 'percent'
                        //     }
                        // },
                        tooltip: {
                          dateTimeLabelFormats: {
                            millisecond: '',
                            second: '',
                            minute: '',
                            hour: '',
                            day: '',
                            week: '',
                            month:"%Y-%m",
                            year: '%m-%Y'
                          },
                          pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>$ {point.y}</b><br/>',
                          valueDecimals: 2
                        },
                        series: seriesOptions
                    });
                };
            seriesOptions = #{datos.to_json};
            createChart();
        });
        </script>
      HTML
    elsif tipo_g == "flot_visitors"
      datos  = props_g[:datos]  rescue []
      # Como las graficas aceptan solo timestamps * 1000, se convierten las fechas
      datos.each do |d|
        d['data'].each do |dd|
          break if dd[0].to_i > 20990000
          dd[0] = Date.parse(dd[0]).to_time.to_i * 1000 if dd[0].to_i < 20990000
        end
      end
      labels = props_g[:labels] rescue [nil]
      div_id = ('a'..'z').to_a.shuffle[0,8].join
      html = <<-HTML
        <!--[if lte IE 8]><script language="javascript" type="text/javascript" src="../../excanvas.min.js"></script><![endif]-->
        <script language="javascript" type="text/javascript" src="/js/jquery.flot.js"></script>
        <script language="javascript" type="text/javascript" src="/js/jquery.flot.time.js"></script>
        <script language="javascript" type="text/javascript" src="/js/jquery.flot.selection.js"></script>
        <div id="content">
          <div class="demo-container" style="height:500px;">
            <div id="#{div_id}" class="demo-placeholder" style="height:500px;"></div>
          </div>
          <div class="demo-container" style="height:150px;">
            <div id="#{div_id}overview" class="demo-placeholder" style="height:150px;"></div>
          </div>
        </div>
        <script type="text/javascript">
          $(function() {
            var d = #{datos[0].to_json};
            var options = {
              xaxis: {
                mode: "time",
                tickLength: 5
              },
              selection: {
                mode: "x"
              }
            };
            var plot = $.plot("##{div_id}", [d], options);
            var overview = $.plot("##{div_id}overview", [d], {
              series: {
                lines: {
                  show: true,
                  lineWidth: 1
                },
                shadowSize: 0
              },
              xaxis: {
                ticks: [],
                mode: "time"
              },
              yaxis: {
                ticks: [],
                min: 0,
                autoscaleMargin: 0.1
              },
              selection: {
                mode: "x"
              }
            });

            $("##{div_id}").bind("plotselected", function (event, ranges) {

              // do the zooming
              $.each(plot.getXAxes(), function(_, axis) {
                var opts = axis.options;
                opts.min = ranges.xaxis.from;
                opts.max = ranges.xaxis.to;
              });
              plot.setupGrid();
              plot.draw();
              plot.clearSelection();

              // don't fire event on the overview to prevent eternal loop

              overview.setSelection(ranges, true);
            });

            $("##{div_id}overview").bind("plotselected", function (event, ranges) {
              plot.setSelection(ranges);
            });
          });
        </script>
      HTML
    end
    html.html_safe
  end

  def despliega_grafica2(tipo_g, props_g)
    html = ""
    series     = props_g[:series]     rescue []
    categorias = props_g[:categorias] rescue [nil]
    titulo     = props_g[:titulo]     rescue nil
    subtitulo  = props_g[:subtitulo]  rescue nil
    ytitulo    = props_g[:ytitulo]    rescue nil
    tultip     = props_g[:tultip]     rescue nil
    if tipo_g == "lineas"
      html = <<-HTML
        <script src="http://code.highcharts.com/highcharts.js"></script>
        <script src="http://code.highcharts.com/modules/exporting.js"></script>
        <div id="container" style="min-width: 310px; height: 400px; margin: 0 auto"></div>
        <script>
          $(function(){
            new Highcharts.Chart({
              chart: {
                  renderTo: 'container',
                  type: 'spline',
                  marginRight: 130,
                  marginBottom: 25
              },
              title: {
                  text: '#{titulo}',
                  x: -20 //center
              },
              subtitle: {
                  text: '#{subtitulo}',
                  x: -20
              },
              xAxis: {
                  categories: #{categorias.to_json},
              },
              yAxis: {
                  title: {
                      text: '#{ytitulo}'
                  },
                  plotLines: [{
                      value: 0,
                      width: 1,
                      color: '#808080'
                  }]
              },
              tooltip: {
                  valueSuffix: '#{tultip}'
              },
              legend: {
                  layout: 'vertical',
                  align: 'right',
                  verticalAlign: 'top',
                  x: -30,
                  y: 40,
                  borderWidth: 0
              },
              series: #{series.to_json}
            });
          });
        </script>
      HTML
    end
    html.html_safe
  end

  def get_modulo_root(rp)
    # Regresa el root del modulo actual. Debe existir @modulos
    ret = "/"
    get_modulos_usuario if !@modulos
    if @modulos
      @modulos.each do |modulo|
        if rp.include?(modulo[:url][0..-2])
          return "/#{modulo[:url]}"
        end
      end
    end
    return ret
  end

  def get_role_name(role)
    return @niveles.select { |item|  item[1] == role.to_i }.first[0] rescue "Desconocido"
  end

  def get_roles_names(roles)
    # Regresa el nombre de los roles separados por comas. Ej: 5,10 > Contralor,Regional
    return "" if roles == ""
    ret = []
    roles.split(',').each{ |r| ret.push(get_role_name(r)) }
    return ret.join(", ")
  end

  def get_nom_frecuencia(f)
    ret = "Diaria"
    ret = "Semanal" if f.to_i == 1
    ret = "Mensual" if f.to_i == 2
    ret
  end
end
