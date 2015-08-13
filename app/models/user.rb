class User < ActiveRecord::Base

  include Blacklight::User
  include Cul::Omniauth::Users

  attr_accessor :password 
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable, :omniauthable
  # :registerable, :recoverable
#  devise :database_authenticatable,
#         :rememberable, :trackable, :validatable

  validates :email, presence: true
  validates :encrypted_password, presence: true, on: :create

  def password
    @password || Devise.friendly_token[0,20]
  end

  def is_admin?
    return self.is_admin
  end

  def role_symbols
    @roles ||= [:"#{self.uid}"]
  end

  def role? role_sym
    return true if role_sym.eql? :*
    return true if role_sym.eql? :"#{self.uid}"
    return false
  end

end
