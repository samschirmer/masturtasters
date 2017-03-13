module DB
	
	ActiveRecord::Base.establish_connection(
	  :adapter => 'sqlite3',
	  :database =>  '../db/tasters.sqlite3.db'
	)
	
	class Category < ActiveRecord::Base
		def self.details(category_id)
			sql = "SELECT c.*, h.first_name, h.last_name, AVG(r.rating) FROM categories AS c LEFT JOIN humans AS h ON h.id = c.master_id LEFT JOIN ratings AS r ON r.category_id = c.id GROUP BY c.*, h.first_name, h.last_name"
			results = ActiveRecord::Base.connection.execute(sql)
		end
	
	end
end
