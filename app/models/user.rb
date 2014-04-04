class User < ActiveRecord::Base

  has_many :projects, :through => :project_permissions  # For the purposes of enabling specific data elements for each project
  has_many :project_permissions, :dependent => :destroy
  has_many :asynchronous_jobs
  
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

  def is_project_admin_for_at_least_one_project?

    if is_admin?
      return true
    elsif ProjectPermission.where(user: self, is_project_admin: true).count > 0
      return true
    end

    return false
  end
  
  def has_project_permission?(project, permission_type)
    valid_permission_types = [:create, :read, :update, :delete, :admin]
    raise 'Permission type must be a symbol (' + permission_type.to_s + ')' if ! permission_type.is_a?(Symbol)
    raise 'Invalid Permission type: ' + permission_type unless valid_permission_types.include?(permission_type)
    
    possible_project_permission = ProjectPermission.where(user: self, project: project).first
    
    unless possible_project_permission.nil?
      if possible_project_permission.is_project_admin
        return true
      else
        if permission_type != :admin
          return true if possible_project_permission.send(('can_' + permission_type.to_s).to_sym)
        end
      end
    end
    
    return false
    
  end

end