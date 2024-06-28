R4a::Application.routes.draw do

  resources :app_nivels
  resources :reporte_de_problemas

  ActiveAdmin.routes(self)
  root :to => "home#index"
  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users
  resources :homereportes
  get '/new_employee'                    => 'homereportes#new_employee'

  get '/homereportes'                    => 'homereportes#index'
  get '/areas'                           => 'homereportes#new_area'
  get '/editar_area/:id_area'            => 'homereportes#editar_area'
  post '/create_area    '                => 'homereportes#create_area'
  post '/create_employee'                => 'homereportes#create_employee'
  get '/delete_employee'                 => 'homereportes#delete_employee'
  get '/new_task'                        => 'homereportes#new_task'
  get '/delete_task'                     => 'homereportes#delete_task'
  post '/create_task'                    => 'homereportes#create_task'
  get  '/create_taskuser'                => 'homereportes#create_taskuser'
  post '/create_areauser'                => 'homereportes#create_areauser'
  post '/create_areaempleado'            => 'homereportes#create_areaempleado'
  get  '/log_home_office'                => 'homereportes#log_home_office'
  get '/delete_areaempleado'             => 'homereportes#delete_areaempleado'
  get '/delete_areajefe'                 => 'homereportes#delete_areajefe'
  get '/delete_taskuser'                 => 'homereportes#delete_taskuser'
  get '/edit_taskuser'                   => 'homereportes#edit_taskuser'
  post '/update_taskuser'                => 'homereportes#update_taskuser'
  post '/checkjefes'                     => 'homereportes#checkjefes'
  get '/edit_task'                       => 'homereportes#edit_task'
  post '/update_task'                    => 'homereportes#update_task'

  post '/zammad_create'                  => 'home#zammad_create'
  get '/privacy'                         => 'home#privacy'
  get '/ayuda'                           => 'home#ayuda'
  get '/personalizar_menu'               => 'home#personalizar_menu'
  get '/personalizar_menu_t'             => 'home#personalizar_menu_t'


  get 'checadores/enviar_chequeos' => 'checadores#enviar_chequeos'
  #get 'checadores/index'

  get '/app_rol_nivel'                   => 'app_rol_nivel#index'
  get '/app_rol_nivel_acceso'            => 'app_rol_nivel#app_rol_nivel_acceso'

  get 'ant_saldos'                       => 'ant_saldos#ant_saldos'
  get 'ant_saldos_clientes'              => 'ant_saldos#ant_saldos_clientes'
  get 'ant_saldos_clientes_nombre_rfc'   => 'ant_saldos#ant_saldos_clientes_nombre_rfc'
  get 'ant_saldos_cliente'               => 'ant_saldos#ant_saldos_cliente'
  get 'ant_saldos_cliente_datos'         => 'ant_saldos#ant_saldos_cliente_datos'
  post 'ant_saldos_cliente_editar'       => 'ant_saldos#ant_saldos_cliente_editar'
  get 'ant_saldos_cliente_anyo'          => 'ant_saldos#ant_saldos_cliente_anyo'
  get 'ant_saldos_cliente_hist1'         => 'ant_saldos#ant_saldos_cliente_hist1'
  get 'ant_saldos_sucursal'              => 'ant_saldos#ant_saldos_sucursal'
  get 'ant_saldos_detalle'               => 'ant_saldos#ant_saldos_detalle'
  get 'ant_saldos_vencidas'              => 'ant_saldos#ant_saldos_vencidas'
  get 'ant_saldos_comentarios'           => 'ant_saldos#ant_saldos_comentarios'
  get 'ant_saldos_mails'                 => 'ant_saldos#ant_saldos_mails'
  get 'ant_saldos_mails_new'             => 'ant_saldos#ant_saldos_mails_new'
  post 'ant_saldos_mails'                => 'ant_saldos#ant_saldos_mails_create'
  delete 'ant_saldos_mails'              => 'ant_saldos#ant_saldos_mails_delete'
  get 'enviar_mails_de_aclaracion_robot' => 'ant_saldos#enviar_mails_de_aclaracion_robot'
  get 'enviar_mails_de_aclaracion_robot_index' => 'ant_saldos#enviar_mails_de_aclaracion_robot_index'
  get 'ant_saldos_sucursal'              => 'ant_saldos#ant_saldos_sucursal'

  get 'replicasuc'                       => 'replicasuc#replicasuc'

  get 'calc_objetivos'                              => 'calc_objetivos#calc_objetivos'
  get 'calc_objetivos_objetivo'                     => 'calc_objetivos#calc_objetivos_objetivo'
  get 'calc_objetivos_estadistica'                  => 'calc_objetivos#calc_objetivos_estadistica'
  get 'calc_objetivos_analisis'                     => 'calc_objetivos#calc_objetivos_analisis'
  get 'calc_objetivos_ajax_subagrupa'               => 'calc_objetivos#ajax_subagrupa'
  get 'calc_objetivos_ajax_agrupasuc'               => 'calc_objetivos#ajax_agrupasuc'
  get 'calc_objetivos_gridcrecireal_porce_update'   => 'calc_objetivos#calc_objetivos_gridcrecireal_porce_update'
  get 'calc_objetivos_gridcrecireal_obj_update'     => 'calc_objetivos#calc_objetivos_gridcrecireal_obj_update'

  get 'repobjetivos'                     => 'repobjetivos#repobjetivos_zona'
  get 'repobjetivos_zona'                => 'repobjetivos#repobjetivos_zona'
  get 'repobjetivos_suc'                 => 'repobjetivos#repobjetivos_suc'
  get 'repobjetivos_det_suc'             => 'repobjetivos#repobjetivos_det_suc'

  get 'signos_vitales'                   => 'signos_vitales#signos_vitales_zona'
  get 'signos_vitales_zona'              => 'signos_vitales#signos_vitales_zona'
  get 'signos_vitales_suc'               => 'signos_vitales#signos_vitales_suc'
  get 'signos_vitales_graf'              => 'signos_vitales#signos_vitales_graf'

  get 'estaventas'                       => 'estaventas#estaventas'
  get 'estaventas_ajax_subagrupa'        => 'estaventas#ajax_subagrupa'
  get 'estaventas_ajax_agrupasuc'        => 'estaventas#ajax_agrupasuc'

  get 'comprobantes_nomina'                   => 'comprobantes_nomina#index'
  get 'comprobantes_nomina_descarga/:nomcomp' => 'comprobantes_nomina#comprobantes_nomina_descarga'
  get 'comprobantes_nomina_ayuda'             => 'comprobantes_nomina#ayuda'
  get 'contrato_colectivo'                    => 'comprobantes_nomina#contrato_colectivo'

  get 'claves_pdv' => 'claves_pdv#index'

  get 'bajas'         => 'bajas#index'
  get 'bajas_obra'    => 'bajas#bajas_obra'
  get 'bajas_detalle' => 'bajas#bajas_detalle'
  get 'bajas_mails'       => 'bajas#bajas_mails'
  get 'bajas_mails_new'   => 'bajas#bajas_mails_new'
  post 'bajas_mails'      => 'bajas#bajas_mails_create'
  delete 'bajas_mails'    => 'bajas#bajas_mails_delete'
  get 'bajas_enviar_mails_robot' => 'bajas#bajas_enviar_mails_robot'
  get 'bajas_enviar_mails_robot_index' => 'bajas#bajas_enviar_mails_robot_index'
  get 'bajas/export_excel' => 'bajas#export_excel'

  get 'consultas'                => 'consultas#index'
  get 'consultas_reportes'       => 'consultas#reportes'

  get 'reportes_bi'              => 'reportes_bi#index'
  get 'reportes_bi_reportes'     => 'reportes_bi#reportes'

  get 'contenedores'             => 'contenedores#index'
  get 'contenedores_contenedor'  => 'contenedores#contenedor'
  get 'contenedores_mails'       => 'contenedores#contenedores_mails'
  get 'contenedores_mails_new'   => 'contenedores#contenedores_mails_new'
  post 'contenedores_mails'      => 'contenedores#contenedores_mails_create'
  delete 'contenedores_mails'    => 'contenedores#contenedores_mails_delete'
  get 'contenedores_enviar_mails_robot' => 'contenedores#contenedores_enviar_mails_robot'
  get 'contenedores_enviar_mails_robot_index' => 'contenedores#contenedores_enviar_mails_robot_index'

  get  'conciliaciones'          => 'conciliaciones#index'
  get  'conciliacion'            => 'conciliaciones#show'
  get  'conciliaciones_robot'    => 'conciliaciones#robot'

  get 'obras'                    => 'obras#obras'
  get 'obra'                     => 'obras#obra'
  get 'obra_detalle'             => 'obras#obra_detalle'
  post 'obra_new_comment'        => 'obras#obra_new_comment'
  post 'obra_edit_status'        => 'obras#obra_edit_status'
  post 'obra_porc_desc_script'   => 'obras#obra_porc_desc_script'

  get 'bloqueo_tarjetas_club_comex' => 'bloqueo_tarjetas_club_comex#index'
  get 'bloqueo_tarjetas_club_comex_new' => 'bloqueo_tarjetas_club_comex#new'
  post 'bloqueo_tarjetas_club_comex_create' => 'bloqueo_tarjetas_club_comex#create'
  get 'bloqueo_tarjetas_club_comex_detalle' => 'bloqueo_tarjetas_club_comex#show'
  post 'bloqueo_tarjetas_club_comex_update' => 'bloqueo_tarjetas_club_comex#update'

  get  'todos'                   => 'todos#todos'
  get  'todos_new'               => 'todos#todos_new'
  post 'todos_create'            => 'todos#todos_create'
  post 'todos_update'            => 'todos#todos_update'
  post 'todos_respuesta_create'  => 'todos#todos_respuesta_create'
  get  'todos_show'              => 'todos#todos_show'
  get  'todos_involucrados_edit' => 'todos#todos_involucrados_edit'
  post 'todos_involucrados_edit_post' => 'todos#todos_involucrados_edit_post'
  resources :todos_respuestas_files

  get  'tickets'                   => 'tickets#tickets'
  get  'tickets_new'               => 'tickets#tickets_new'
  post 'tickets_create'            => 'tickets#tickets_create'
  post 'tickets_update'            => 'tickets#tickets_update'
  post 'tickets_respuesta_create'  => 'tickets#tickets_respuesta_create'
  get  'tickets_show'              => 'tickets#tickets_show'
  get  'tickets_involucrados_edit' => 'tickets#tickets_involucrados_edit'
  post 'tickets_involucrados_edit_post' => 'tickets#tickets_involucrados_edit_post'
  get  'tickets_assign_myself'     => 'tickets#tickets_update'
  get  'tickets_programados'       => 'tickets#tickets_programados'
  get  'tickets_programados_new'   => 'tickets#tickets_programados_new'
  post 'tickets_programados_create'=> 'tickets#tickets_programados_create'
  get  'tickets_programados_edit'  => 'tickets#tickets_programados_edit'
  post 'tickets_programados_update'=> 'tickets#tickets_programados_update'
  delete 'tickets_programados_destroy' => 'tickets#tickets_programados_destroy'
  get  'tickets_programados_robot' => 'tickets#tickets_programados_robot'
  resources :tickets_respuestas_files, only: [:create]

  get  'revisiones'                => 'revisiones#revisiones'
  get  'revisiones_new'            => 'revisiones#revisiones_new'
  post 'revisiones_create_preview' => 'revisiones#revisiones_create_preview'
  post 'revisiones_create'         => 'revisiones#revisiones_create'
  get  'revisiones_show'           => 'revisiones#revisiones_show'

  get  'grupos'                   => 'grupos#grupos'
  get  'grupos_new'               => 'grupos#grupos_new'
  post 'grupos_create'            => 'grupos#grupos_create'
  get  'grupos_edit'              => 'grupos#grupos_edit'
  post 'grupos_update'            => 'grupos#grupos_update'
  delete 'grupos_destroy'         => 'grupos#grupos_destroy'
  get  'grupos_update_rol'        => 'grupos#grupos_update_rol'

  namespace :supervisiones do
    root :to                        => 'supervisiones#root'

    get  'programadas'              => 'supervisiones#programadas'
    get  'terminadas'               => 'supervisiones#terminadas'
    get  'supervision_terminada'    => 'supervisiones#supervision_terminada'
    get  'crear_supervision'        => 'supervisiones#crear_supervision'
    get  'realizar_supervision'     => 'supervisiones#crear_supervision'
    get  'nueva_supervision'        => 'supervisiones#nueva_supervision'
    post 'nueva_supervision'        => 'supervisiones#nueva_supervision_create'
    get  'supervision_en_curso'     => 'supervisiones#supervision_en_curso'
    post 'supervision_en_curso'     => 'supervisiones#supervision_en_curso_update'
    get  'supervision_en_curso_aci' => 'supervisiones#supervision_en_curso_aci'
    post 'supervision_en_curso_aci' => 'supervisiones#supervision_en_curso_aci_create'
    get  'supervisiones_en_curso'   => 'supervisiones#supervisiones_en_curso'
    get  'supervision_por_aprobar'  => 'supervisiones#supervision_por_aprobar'
    post 'supervision_por_aprobar'  => 'supervisiones#supervision_por_aprobar_update'
    get  'supervisiones_por_aprobar'=> 'supervisiones#supervisiones_por_aprobar'
    get  'supervisiones_por_programar' => 'supervisiones#supervisiones_por_programar'
    get  'programar_supervisiones'  => 'supervisiones#programar_supervisiones'
    post 'programar_supervisiones'  => 'supervisiones#programar_supervisiones_create'
    delete 'programar_supervisiones'=> 'supervisiones#programar_supervisiones_destroy'

    get  'checklists'               => 'checklists#index'
    get  'checklist_new'            => 'checklists#new'
    post 'checklist_create'         => 'checklists#create'
    get  'checklist_edit'           => 'checklists#edit'
    post 'checklist_update'         => 'checklists#update'
    delete 'checklist_destroy'      => 'checklists#destroy'

    get  'categories'               => 'categories#index'
    get  'category_new'             => 'categories#new'
    post 'category_create'          => 'categories#create'
    get  'category_edit'            => 'categories#edit'
    post 'category_update'          => 'categories#update'
    delete 'category_destroy'       => 'categories#destroy'

    get  'campos'                   => 'campos#index'
    get  'campo_new'                => 'campos#new'
    post 'campo_create'             => 'campos#create'
    get  'campo_edit'               => 'campos#edit'
    post 'campo_update'             => 'campos#update'
    delete 'campo_destroy'          => 'campos#destroy'

    get  'load_sucs'                => 'supervisiones#load_sucs'
    get  'load_cats'                => 'supervisiones#load_cats'

    get  'sup_test'                 => 'supervisiones#sup_test'

  end
  resources :sup_imagens

  namespace :notificaciones do
    get 'autorizaciones'            => 'autorizaciones#index'
    get 'autorizaciones/:id'        => 'autorizaciones#show'
    get 'auth_logs'                 => 'auth_logs#index'
    get 'auth_logs/:id'             => 'auth_logs#show'

    get 'notificaciones'            => 'notificaciones#index'

    get 'mails'                     => 'mails#mails'
    get 'mails_new'                 => 'mails#mails_new'
    get 'mails_edit'                => 'mails#mails_edit'
    post 'mails'                    => 'mails#mails_create'
    delete 'mails'                  => 'mails#mails_delete'

    get  'push_tokens'              => 'push_tokens#index'
    get  'push_token_test'          => 'push_tokens#push_token_test'

    resources :webhooks
  end

  get 'medidores' => 'tableros/layouts#index'
  get 'medidores_prueba' => 'tableros/medidores#prueba'
  namespace :tableros do
    root :to                        => 'layouts#index'

    resources :layouts
    resources :medidores
    get 'medidores_display_medidor' => 'medidores#medidores_display_medidor'
    resources :usuarios
  end

  namespace :auths do
    root :to                        => 'solicitudes#index'

    resources :solicitudes
    get 'solicitudes_update'  => 'solicitudes#update'
    post 'solicitudes_respuesta_create'  => 'solicitudes#respuesta_create'
    resources :flujos, except: [:edit, :update]
    resources :tipo_solicitudes
  end
  resources :auths_respuestas_files, only: [:create]

  namespace :ecommerce do
    root :to                        => 'pedidos#index'

    resources :pedidos, only: [:index, :show]
    post 'asignar_sucursal'  => 'pedidos#asignar_sucursal'
    post 'cambiar_status'  => 'pedidos#cambiar_status'

    resources :webservices, only: [:index, :show]
  end

  get 'webservices'                 => 'webservices#index'
  get 'webservices/pdv'             => 'webservices#pdv'
  post 'webservices/pdv/autoriza'   => 'webservices#pdv_autoriza'
  post 'webservices/ecommerce/pedido' => 'webservices#ecommerce_pedido'

  get  'documentos'                   => 'documentos#index'
  get  'documentos_admin'             => 'documentos#documentos_admin'
  get  'documentos_admin_new'         => 'documentos#documentos_admin_new'
  post 'documentos_admin_create'      => 'documentos#documentos_admin_create'
  get  'documentos_admin_edit'        => 'documentos#documentos_admin_edit'
  post 'documentos_admin_update'      => 'documentos#documentos_admin_update'
  delete 'documentos_admin_destroy'   => 'documentos#documentos_admin_destroy'
  get  'documentos_admin_image'       => 'documentos#documentos_admin_image'
  get  'documentos_admin_file'        => 'documentos#documentos_admin_file'
  get  'documentos_admin_multiple_files' => 'documentos#documentos_admin_multiple_files'

  resources :documentos_images
  resources :documentos_files

  get  'stock_sucursales'              => 'stock_sucursales#stock_sucursales'
  get  'stock_sucursales_existencias'  => 'stock_sucursales#stock_sucursales_existencias'

  get  'pdv'                    => 'pdv#pdv'
#  get  'pdv_devolver'           => 'pdv#pdv_devolver'
  get  'pdv_selvend'            => 'pdv#pdv_selvend'
  get  'pdv_selcli'             => 'pdv#pdv_selcli'
  get  'pdv_selsuc'             => 'pdv#pdv_selsuc'
  get  'pdv_selobra'            => 'pdv#pdv_selobra'
  get  'pdv_selprod'            => 'pdv#pdv_selprod'
  get  'pdv_selprod_edit'       => 'pdv#pdv_selprod_edit'
  post 'pdv_selprod_update'     => 'pdv#pdv_selprod_update'
  get  'pdv_selprod_destroy'    => 'pdv#pdv_selprod_destroy'
  get  'pdv_desc_global_edit'   => 'pdv#pdv_desc_global_edit'
  post 'pdv_desc_global_update' => 'pdv#pdv_desc_global_update'
  get  'pdv_cotiza_edit'        => 'pdv#pdv_cotiza_edit'
  post 'pdv_cotiza_update'      => 'pdv#pdv_cotiza_update'
  get  'pdv_pendientes'         => 'pdv#pdv_pendientes'
  get  'pdv_cotiza_terminada'   => 'pdv#pdv_cotiza_terminada'

  get  'estadisticas_ventas'   => 'estadisticas_ventas#index'
  get  'estadisticas_ventas/superior/:id'   => 'estadisticas_ventas#superior'
  get  'estadisticas_ventas/superior/intermedio/:id'   => 'estadisticas_ventas#intermedio'
  get  'estadisticas_ventas/superior/intermedio/sucursal/:id'   => 'estadisticas_ventas#sucursal'
  #post  'vendedor/:id'   => 'estadisticas_ventas#show'
  get 'estadisticas_ventas/superior/intermedio/sucursal/:id/vendedor/:id' => 'estadisticas_ventas#show_vendedor'
  post '/search_empleado/:id' => 'comisiones#search_empleado'


  get 'comisiones' => 'comisiones#index'
  get 'comisiones/:mes/:sucursal/:tipo' => 'comisiones#show_report'

  get 'comisiones_v1' => 'comisiones_v1#index'
  get 'comisiones_v1/:mes/:sucursal/:tipo' => 'comisiones_v1#show_report'
  get 'print_pdf/:id' => 'comisiones_v1#print_pdf'

  get 'reporte_sucursales/:id/:type' => 'reporte_sucursales#show'
  get 'estadisticas_ventas/export_excel' => 'estadisticas_ventas#export_excel'


  get 'reportes_vendedores' => 'reportes_vendedores#index'
  get 'reportes_vendedores/:id' => 'reportes_vendedores#show'
  get 'print_pdf_vend/:id/:month' => 'reportes_vendedores#print_pdf_vend'
  get 'exportar_excel/:month' => 'reportes_vendedores#exportar_excel'
  # get 'tickets/:id/:state' => 'tickets#change_settings'
  # get 'tickets/dashboard_tickets' => 'tickets#dashboard_tickets'
  # resources :tickets, only: [:index, :show, :create]
  # resources :ticket_groups
  resources :reporte_sucursales

  get 'detalle/sucursal/:id/vendedor/:id' =>'estadisticas_ventas#ver_detalle'

  ########################################################################
  # API
  ########################################################################
  namespace :api do
    namespace :v1 do
      get 'alive' => 'welcome#alive'
      get 'auth_alive' => 'welcome#auth_alive'
      resources :sessions, only: [:create, :destroy]
      post 'push_token', to: 'sessions#push_token'
      get 'notificaciones' => 'notificaciones#index'
      resources :calificaciones_reportes
      resources :webservices_auths, only: [:index, :update]
    end
  end

end
