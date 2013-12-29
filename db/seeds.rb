path = File.dirname(__FILE__)
connection = ActiveRecord::Base.connection
seedfile = if File.exists?(path + '/seeds_local.sql')
             path + '/seeds_local.sql'
           else
             path + '/seeds.sql'
           end
statements = IO.read(seedfile).split(';').map(&:strip).reject(&:empty?)

ActiveRecord::Base.transaction do
  statements.each do |statement|
    connection.execute(statement)
  end
end
