class User < ActiveRecord::Base

  include Blacklight::User
  include Cul::Omniauth::Users

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable, :omniauthable
  # :registerable, :recoverable
  devise :database_authenticatable,
         :rememberable, :trackable, :validatable

  validates :email, :first_name, :last_name, presence: true
  validates :password, :password_confirmation, presence: true, on: :create

  def full_name
    return self.first_name + ' ' + self.last_name
  end

  def is_admin?
    return self.is_admin
  end
  def role_symbols
    @roles ||= [:"#{self.login}"]
  end
  def role? role_sym
    return true if role_sym.eql? :*
    return true if role_sym.eql? :"#{self.login}"
    return false
  end

end
