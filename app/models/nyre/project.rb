module Nyre
  class Project < ActiveRecord::Base
    self.table_name_prefix = 'nyre_'
    validates :call_number, presence: true
  end
end