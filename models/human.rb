module DB
	
	class Human < ActiveRecord::Base
		def self.test(category_id)
			sql = "select h.firstname, r.rating, b.name from ratings as r left join humans as h on h.id = r.human_id left join brands as b on b.id = r.brand_id where b.category_id = #{category_id} order by rating desc"
			results = ActiveRecord::Base.connection.execute(sql)
		end
	end
end
