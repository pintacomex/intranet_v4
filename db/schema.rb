# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190415224741) do

  create_table "Homereportes", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "fecha",       limit: 10,  default: "", null: false
    t.string   "start",       limit: 5,   default: "", null: false
    t.string   "finish",      limit: 5,   default: "", null: false
    t.string   "descripcion", limit: 255, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body",          limit: 65535
    t.string   "resource_id",   limit: 255,   null: false
    t.string   "resource_type", limit: 255,   null: false
    t.integer  "author_id",     limit: 4
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "ant_saldos_emails_enviados", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.date     "fecha"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "app_nivels", force: :cascade do |t|
    t.integer  "app",         limit: 4
    t.integer  "nivel",       limit: 4
    t.string   "descripcion", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "app_rol_nivels", force: :cascade do |t|
    t.integer  "app",        limit: 4
    t.integer  "rol",        limit: 4
    t.integer  "nivel",      limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "apps", force: :cascade do |t|
    t.string   "nombre",     limit: 255
    t.string   "url",        limit: 255
    t.string   "bloque",     limit: 255
    t.integer  "activo",     limit: 4,   default: 0, null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "areajeves", force: :cascade do |t|
    t.string   "id_user",    limit: 255
    t.string   "id_area",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "areas", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "areausers", force: :cascade do |t|
    t.string   "id_user",    limit: 255
    t.string   "id_area",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "auth_logs", force: :cascade do |t|
    t.integer  "empresa",     limit: 4
    t.integer  "sucursal",    limit: 4
    t.integer  "pc",          limit: 4
    t.string   "numAuth",     limit: 255
    t.integer  "nivel",       limit: 4
    t.datetime "fechaHora"
    t.text     "descripcion", limit: 65535
    t.string   "status",      limit: 255
    t.text     "respuesta",   limit: 65535
    t.integer  "pdvPrueba",   limit: 4,     default: 0
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "auth_logs", ["numAuth"], name: "index_auth_logs_on_numAuth", unique: true, using: :btree

  create_table "auths_respuestas_files", force: :cascade do |t|
    t.integer  "IdSolicitud",       limit: 4
    t.integer  "IdRespuesta",       limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
    t.integer  "Usuario",           limit: 4
  end

  create_table "calificacionreportes", force: :cascade do |t|
    t.string  "fecha",   limit: 10, default: "", null: false
    t.integer "user_id", limit: 4
    t.string  "rating",  limit: 2,  default: "", null: false
  end

  create_table "cat_roles", force: :cascade do |t|
    t.string   "nomPermiso", limit: 255
    t.integer  "nivel",      limit: 4
    t.string   "nomP1",      limit: 255
    t.string   "nomP2",      limit: 255
    t.string   "nomP3",      limit: 255
    t.string   "nomP4",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "checklist_items", force: :cascade do |t|
    t.integer  "checklist_id", limit: 4,   default: 0,  null: false
    t.string   "texto",        limit: 255, default: "", null: false
    t.integer  "orden",        limit: 4,   default: 0,  null: false
    t.integer  "status",       limit: 4,   default: 1,  null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "checklists", force: :cascade do |t|
    t.string   "nombre",     limit: 255, default: "", null: false
    t.integer  "status",     limit: 4,   default: 1,  null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "documentos_files", force: :cascade do |t|
    t.string   "CveAnt",            limit: 255
    t.string   "Clave",             limit: 255
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
  end

  create_table "documentos_images", force: :cascade do |t|
    t.string   "CveAnt",              limit: 255
    t.string   "Clave",               limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "imagen_file_name",    limit: 255
    t.string   "imagen_content_type", limit: 255
    t.integer  "imagen_file_size",    limit: 4
    t.datetime "imagen_updated_at"
  end

  create_table "empresas", force: :cascade do |t|
    t.integer  "idEmpresa",  limit: 2,     default: 0,  null: false
    t.string   "nombre",     limit: 50,    default: "", null: false
    t.integer  "idRfc",      limit: 4,     default: 0,  null: false
    t.text     "privacidad", limit: 65535,              null: false
    t.string   "email",      limit: 50,    default: "", null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "int_params", force: :cascade do |t|
    t.string   "nombre_param", limit: 255
    t.string   "valor_param",  limit: 255
    t.string   "desc_param",   limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "log_usuarios", force: :cascade do |t|
    t.integer  "id_user",     limit: 4
    t.integer  "id_app",      limit: 4
    t.string   "accion",      limit: 255
    t.string   "descripcion", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "medidores", force: :cascade do |t|
    t.string   "tipo",       limit: 255,   default: "GaugePorcentual",    null: false
    t.string   "titulo",     limit: 255,   default: "Ventas vs Objetivo", null: false
    t.string   "subtitulo1", limit: 255,   default: "Objetivo:",          null: false
    t.string   "subtitulo2", limit: 255,   default: "Alcance:",           null: false
    t.text     "valor",      limit: 65535
    t.text     "minimo",     limit: 65535
    t.text     "maximo",     limit: 65535
    t.string   "simbolo",    limit: 255,   default: "%",                  null: false
    t.text     "opciones",   limit: 65535
    t.integer  "activado",   limit: 4,     default: 1,                    null: false
    t.string   "roles",      limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
  end

  create_table "menu_customizes", force: :cascade do |t|
    t.integer  "idUsuario",  limit: 4
    t.string   "modulo",     limit: 255
    t.boolean  "escondido"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "notificaciones", force: :cascade do |t|
    t.string   "tipo",         limit: 255
    t.string   "destinatario", limit: 255
    t.text     "texto",        limit: 65535
    t.integer  "status",       limit: 4
    t.string   "deviceId",     limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "permisos", force: :cascade do |t|
    t.integer  "idUsuario",  limit: 4
    t.string   "permiso",    limit: 255
    t.string   "p1",         limit: 255
    t.string   "p2",         limit: 255
    t.string   "p3",         limit: 255
    t.string   "p4",         limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "push_tokens", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "push_token", limit: 255
    t.string   "deviceId",   limit: 255
    t.string   "deviceName", limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "reporte_de_problemas", force: :cascade do |t|
    t.integer  "sitio",       limit: 4
    t.string   "nombre",      limit: 255
    t.string   "email",       limit: 255
    t.string   "ciudad",      limit: 255
    t.text     "descripcion", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "resource_id",   limit: 4
    t.string   "resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "sitios", force: :cascade do |t|
    t.integer  "idEmpresa",  limit: 2,     default: 0,  null: false
    t.integer  "idZona",     limit: 2,     default: 0,  null: false
    t.string   "nombre",     limit: 30,    default: "", null: false
    t.string   "sufijo",     limit: 3,     default: "", null: false
    t.string   "nombreWeb",  limit: 30,    default: "", null: false
    t.text     "mapa",       limit: 65535,              null: false
    t.string   "ipServer",   limit: 255,   default: "", null: false
    t.string   "basePdv",    limit: 30,    default: "", null: false
    t.string   "baseFacEle", limit: 30,    default: "", null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "sup_imagens", force: :cascade do |t|
    t.integer  "Sucursal",         limit: 4
    t.integer  "IdVisita",         limit: 4
    t.integer  "IdChecklist",      limit: 4
    t.integer  "IdCatChecklist",   limit: 4
    t.integer  "IdCampo",          limit: 4
    t.integer  "Usuario",          limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "img_file_name",    limit: 255
    t.string   "img_content_type", limit: 255
    t.integer  "img_file_size",    limit: 4
    t.datetime "img_updated_at"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer  "task_id",     limit: 4
    t.string   "descripcion", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "taskusers", force: :cascade do |t|
    t.integer  "id_task",         limit: 4
    t.integer  "id_user",         limit: 4
    t.string   "fecha_inicio",    limit: 255
    t.string   "fecha_limite",    limit: 255
    t.integer  "creado_por",      limit: 4
    t.string   "fecha_termina",   limit: 255
    t.integer  "porc_terminado",  limit: 4
    t.string   "fecha_procesado", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "todos_respuestas_files", force: :cascade do |t|
    t.integer  "IdHTodo",           limit: 4
    t.integer  "IdRespuesta",       limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
    t.integer  "Usuario",           limit: 4
  end

  create_table "userhomes", force: :cascade do |t|
    t.string   "user_id",     limit: 255
    t.string   "id_token",    limit: 255
    t.string   "fecha_start", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: ""
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                   limit: 255
    t.integer  "idEmpresa",              limit: 2,   default: 0,  null: false
    t.integer  "numEmpleado",            limit: 4,   default: 0,  null: false
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.string   "invitation_token",       limit: 255
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit",       limit: 4
    t.integer  "invited_by_id",          limit: 4
    t.string   "invited_by_type",        limit: 255
    t.datetime "password_changed_at"
    t.string   "authentication_token",   limit: 30
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["password_changed_at"], name: "index_users_on_password_changed_at", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.integer "role_id", limit: 4
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "webhooks", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "value",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "webservices_auths", force: :cascade do |t|
    t.integer  "sucursal",    limit: 4
    t.text     "descripcion", limit: 65535
    t.text     "respuesta",   limit: 65535
    t.integer  "status",      limit: 4,     default: 0
    t.datetime "fechaHora"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "pc",          limit: 4
    t.string   "numAuth",     limit: 255,   default: "", null: false
    t.integer  "nivel",       limit: 4
    t.integer  "empresa",     limit: 4,     default: 1
  end

  create_table "zonas", force: :cascade do |t|
    t.integer  "idZona",     limit: 2,  default: 0,  null: false
    t.string   "nombre",     limit: 50, default: "", null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

end
