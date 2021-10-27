module Nyre
  class Project < ApplicationRecord
    self.table_name_prefix = 'nyre_'
    validates :call_number, presence: true
  end
end