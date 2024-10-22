R4a::Application.routes.draw do

  resources :app_nivels
  resources :reporte_de_problemas


  ActiveAdmin.routes(self)
  root :to => "home#index"
  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users
  resources :homereportes
  get '/new_employee'                    => 'homereportes#new_employee'
  get '/dashboard'                       => 'homereportes#dashboard'
  post '/create_employee'                => 'homereportes#create_employee'
  get '/delete_employee'                 => 'homereportes#delete_employee'
  get '/new_task'                        => 'homereportes#new_task'
  get '/delete_task'                        => 'homereportes#delete_task'
  post '/create_task'                    => 'homereportes#create_task'
  post '/create_taskuser'                    => 'homereportes#create_taskuser'

  post '/zammad_create'                  => 'home#zammad_create'
  get '/privacy'                         => 'home#privacy'
  get '/ayuda'                           => 'home#ayuda'
  get '/personalizar_menu'               => 'home#personalizar_menu'
  get '/personalizar_menu_t'             => 'home#personalizar_menu_t'

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
  get 'bajas/export_excel' => 'bajas#export_excel'


  get  'conciliaciones'          => 'conciliaciones#index'
  get  'conciliacion'            => 'conciliaciones#show'
  get  'conciliaciones_robot'    => 'conciliaciones#robot'

  get 'obras'                    => 'obras#obras'
  get 'obra'                     => 'obras#obra'
  get 'obra_detalle'             => 'obras#obra_detalle'
  post 'obra_new_comment'        => 'obras#obra_new_comment'
  post 'obra_edit_status'        => 'obras#obra_edit_status'
  post 'obra_porc_desc_script'   => 'obras#obra_porc_desc_script'

  get  'todos'                   => 'todos#todos'
  get  'todos_new'               => 'todos#todos_new'
  post 'todos_create'            => 'todos#todos_create'
  post 'todos_update'            => 'todos#todos_update'
  post 'todos_respuesta_create'  => 'todos#todos_respuesta_create'
  get  'todos_show'              => 'todos#todos_show'
  get  'todos_involucrados_edit' => 'todos#todos_involucrados_edit'
  post 'todos_involucrados_edit_post' => 'todos#todos_involucrados_edit_post'
  resources :todos_respuestas_files

  get  'tickets_v2'                   => 'tickets_v2#tickets'
  get  'tickets_v2_new'               => 'tickets_v2#tickets_new'
  post 'tickets_v2_create'            => 'tickets_v2#tickets_create'
  post 'tickets_v2_update'            => 'tickets_v2#tickets_update'
  post 'tickets_v2_respuesta_create'  => 'tickets_v2#tickets_respuesta_create'
  get  'tickets_v2_show'              => 'tickets_v2#tickets_show'
  get  'tickets_v2_involucrados_edit' => 'tickets_v2#tickets_involucrados_edit'
  post 'tickets_v2_involucrados_edit_post' => 'tickets_v2#tickets_involucrados_edit_post'
  get  'tickets_v2_assign_myself'     => 'tickets_v2#tickets_update'
  resources :tickets_v2_respuestas_files

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

  get 'webservices'                 => 'webservices#index'
  get 'webservices/pdv'             => 'webservices#pdv'
  post 'webservices/pdv/autoriza'   => 'webservices#pdv_autoriza'

  get  'documentos'                   => 'documentos#index'
  get  'documentos_admin'             => 'documentos#documentos_admin'
  get  'documentos_admin_new'         => 'documentos#documentos_admin_new'
  post 'documentos_admin_create'      => 'documentos#documentos_admin_create'
  get  'documentos_admin_edit'        => 'documentos#documentos_admin_edit'
  post 'documentos_admin_update'      => 'documentos#documentos_admin_update'
  delete 'documentos_admin_destroy'   => 'documentos#documentos_admin_destroy'
  get  'documentos_admin_image'       => 'documentos#documentos_admin_image'
  get  'documentos_admin_file'        => 'documentos#documentos_admin_file'

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
  get 'print_pdf/:id' => 'comisiones#print_pdf'
  get 'estadisticas_ventas/superior/intermedio/sucursal/:id/vendedor/:id' => 'estadisticas_ventas#show_vendedor'


  get 'comisiones' => 'comisiones#index'
  get 'comisiones/:mes/:sucursal' => 'comisiones#show_report'

  get 'reporte_sucursales/:id/:type' => 'reporte_sucursales#show'
  get 'estadisticas_ventas/export_excel' => 'estadisticas_ventas#export_excel'
  
  get 'tickets/:id/:state' => 'tickets#change_settings'
  get 'tickets/dashboard_tickets' => 'tickets#dashboard_tickets'
  resources :tickets, only: [:index, :show, :create]
  resources :ticket_groups
  resources :reporte_sucursales

  get  'detalle/sucursal/:id/vendedor/:id' =>'estadisticas_ventas#ver_detalle'
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
