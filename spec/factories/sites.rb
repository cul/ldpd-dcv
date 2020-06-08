# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    title { 'DLC Site' }
    persistent_url   { 'https://example.com/catalog/persistent_url' }
    restricted { false }
    layout { 'catalog' }
    palette { 'monochromeDark'}
    search_type { 'catalog' }
    image_uri { 'info:fedora/test-image:1' }
    repository_id { 'NNC'}
  end
end