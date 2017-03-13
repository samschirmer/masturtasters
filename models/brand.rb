module DB
	
	ActiveRecord::Base.establish_connection(
	  :adapter => 'sqlite3',
	  :database =>  '../db/tasters.sqlite3.db'
	)
	
	class Brand < ActiveRecord::Base
		def self.get_overall_stats(category_id)
			sql = "select b.name, avg(r.rating) as avg_rating, avg(r.ranking) as avg_ranking from brands as b left join ratings as r on r.brand_id = b.id where b.category_id = #{category_id} group by r.brand_id order by avg(r.rating) desc"
			results = ActiveRecord::Base.connection.execute(sql)
			return results
		end
	end
end
