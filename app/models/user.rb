class User < ActiveRecord::Base
  #attr_accessible :name, :email, :password, :password_confimation, :store
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :idEmpresa, :numEmpleado
  acts_as_token_authenticatable
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise  :database_authenticatable, :recoverable, :rememberable, :trackable, :timeoutable, :registerable # , :registerable, , :password_expirable, :invitable, :confirmable, :validatable

  before_create :assign_role

  has_many :push_tokens

  validates_uniqueness_of    :email,     :case_sensitive => false, :allow_blank => true, :if => :email_changed?
  # validates_format_of    :email,    :with  => Devise.email_regexp, :allow_blank => true, :if => :email_changed?
  validates_presence_of    :password, :on=>:create
  validates_confirmation_of    :password, :on=>:create
  validates_length_of    :password, :within => Devise.password_length, :allow_blank => true

  def assign_role
    self.add_role :user if self.roles.first.nil?
  end

  def self.authenticate(email, password)
    auth = find_by_email email
    if auth && auth.valid_password?(password)
      if auth.authentication_token.blank?
        auth.authentication_token = Devise.friendly_token
        auth.save!
      end
      auth
    end
  end

end
