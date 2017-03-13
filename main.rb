require 'sinatra'
require 'active_record'
require 'securerandom'
require 'chartkick'
require 'require_all'
require_all 'models'
include DB

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3',:database =>  'db/tasters.sqlite3.db')
# hack because activesuport is fucking retarded apparently; humen? really?
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'human', 'humans'
end

# MAIN VIEW ACTIONS
get '/' do 
	@categories = DB::Category.find_by_sql("select c.id, c.name, c.master_id, h.first_name as master, c.date_tasted, AVG(r.rating) as avg_rating, AVG(r.ranking) as avg_ranking from categories as c left join humans as h on h.id = c.master_id left join ratings as r on r.category_id = c.id group by c.id, c.name, h.first_name, c.date_tasted")
	@humans = DB::Human.all
	erb :index
end

get '/categories/:id' do 
	@brands = DB::Brand.find_by_sql("select b.id, b.name, avg(r.rating) as avg_rating, avg(r.ranking) as avg_ranking from brands as b left join ratings as r on r.brand_id = b.id where b.category_id = #{params[:id]} group by r.brand_id order by avg(r.rating) desc")
	@category = DB::Category.find_by_id(params[:id])
	erb :category
end

get '/humans/:id' do 
	@human = DB::Human.find_by_id(params[:id])
	@favorites = DB::Human.find_by_sql("select c.name as category, b.name as brand from ratings as r left join brands as b on r.brand_id = b.id left join categories as c on c.id = r.category_id where r.ranking = 1 and human_id = #{params[:id]}")
	erb :human
end

get '/brands/:id' do 
	@ratings = Array.new
	@percent = Array.new
	@brand = DB::Brand.find_by_sql("select b.id, b.name, avg(r.rating) as avg_rating, avg(r.ranking) as avg_ranking, sum(r.rating) as sum_rating, c.name as category from brands as b left join ratings as r on r.brand_id = b.id left join categories as c on c.id = b.category_id where b.id = #{params[:id]} group by r.brand_id order by avg(r.rating) desc").first

	# RATINGS BAR CHART
	ratings_chart = DB::Rating.find_by_sql("select h.first_name, r.rating from ratings as r left join humans as h on h.id = r.human_id where r.brand_id = #{params[:id]} order by r.rating desc")
	ratings_chart.each do |c|
		@percent.push([c.first_name, (c.rating / @brand.sum_rating).round(2) * 100])
		@ratings.push([c.first_name, c.rating])
	end

	erb :brand
end

# releasing connection because thin and activerecord are assholes
after do
  ActiveRecord::Base.connection.close
end
