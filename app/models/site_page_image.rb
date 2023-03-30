class SitePageImage < ApplicationRecord
	belongs_to :depictable, polymorphic: true, touch: true
end