# frozen_string_literal: true

FactoryBot.define do
  factory :nyre_project, class: Nyre::Project do
    call_number { 'YR.0018.BR' }
    name { 'Appraised Homes' }
  end
end