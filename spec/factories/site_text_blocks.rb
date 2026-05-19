# frozen_string_literal: true

FactoryBot.define do
  factory :site_text_block do
    sort_label { '00:Text Block'}
    markdown { '# Hello' }
  end
end