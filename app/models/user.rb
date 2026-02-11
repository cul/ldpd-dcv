class User < ApplicationRecord
# Connects this user object to Blacklights Bookmarks.
include Blacklight::User

# Blacklight::User uses a method on your User class to get a user-displayable
# label (e.g. login or identifier) for the account. Blacklight uses `email' by default.
# self.string_display_key = :email
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
