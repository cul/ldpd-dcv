# frozen_string_literal: true

FactoryBot.define do
  factory :site_page do
    slug { 'dlc_site_page' }
    title { 'DLC Site Page' }
    columns { 1 }
  end
end