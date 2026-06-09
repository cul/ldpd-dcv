# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    slug { 'dlc_site' }
    title { 'DLC Site' }
    persistent_url   { 'https://example.com/catalog/persistent_url' }
    restricted { false }
    layout { 'default' }
    palette { 'monochromeDark'}
    search_type { 'catalog' }
    image_uris { ['info:fedora/test-image:1'] }
    repository_id { 'NNC'}
    scope_filters { [build(:scope_filter, filter_type: 'collection', value: 'DLC Site Collection')] }
    association :owner, factory: :user

    factory :site_with_links do
      after(:create) do |site|
        # When a NavLink is created via the editor interface, it always has a sort_label with a numbered prefix and a
        # sort_group with a numbered prefix (even if the sort_group label is blank and it renders at the top level)
        create(:nav_link, site_id: site.id, external: false, link: 'about', sort_group: '00:', sort_label: '00:About')
        create(:nav_link, site_id: site.id, external: false, link: 'funding', sort_group: '01:Project History', sort_label: '00:Funding')
        create(:nav_link, site_id: site.id, external: false, link: 'contributors', sort_group: '01:Project History', sort_label: '01:Contributors')
      end
    end

    factory :site_with_pages do
      after(:create) do |site|
        create(:site_page, site_id: site.id)
        create(:site_page, site_id: site.id, slug: 'another_page', title: 'Another Page')
        create(:site_page_with_text_blocks, site_id: site.id, slug: 'home', title: 'Home Page with Text')
      end
    end
  end
end