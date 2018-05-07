# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'csv'

CSV.foreach("db/seeds/nyre_projects.csv", headers: true) do |row|
  project = Nyre::Project.find_or_initialize_by(id: row['id'].to_i)
  unless project.persisted?
    project.id = row['id'].to_i
    project.name = row['name']
    project.call_number = row['call_number']
    project.save!
  end
end