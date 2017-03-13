module DB
	ActiveRecord::Base.establish_connection(
	  :adapter => 'sqlite3',
	  :database =>  '../db/tasters.sqlite3.db'
	)
	class Human < ActiveRecord::Base
	end
	class Category < ActiveRecord::Base
	end
	class Brand < ActiveRecord::Base
	end
	class Rating < ActiveRecord::Base
	end
end
