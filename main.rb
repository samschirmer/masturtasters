require 'sinatra'
require 'active_record'
require 'securerandom'
require 'chartkick'
require_relative './tables'
include DB

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3',:database =>  'db/tasters.sqlite3.db')
# hack because activesuport is fucking retarded apparently; humen? really?
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'human', 'humans'
end

# MAIN VIEW ACTIONS
get '/' do 
	@top_chart = Array.new
	@bottom_chart = Array.new
	@categories = DB::Category.find_by_sql("select c.id, c.name, c.master_id, h.first_name as master, c.date_tasted, AVG(r.rating) as avg_rating, AVG(r.ranking) as avg_ranking from categories as c left join humans as h on h.id = c.master_id left join ratings as r on r.category_id = c.id group by c.id, c.name, h.first_name, c.date_tasted")
	@humans = DB::Human.all

	# top brands chart
	top_brands = DB::Rating.find_by_sql("select c.name as category, b.name as brand, avg(r.rating) as Average from ratings as r left join brands as b on b.id = r.brand_id left join categories as c on c.id = r.category_id group by b.id order by avg(r.rating) desc limit 10")
	top_brands.each do |b|
		brand = "#{b.category.upcase}: #{b.brand.upcase}"
		@top_chart.push([brand, b.Average.round(2)])
	end

	# bottom brands chart
	bottom_brands = DB::Rating.find_by_sql("select c.name as category, b.name as brand, avg(r.rating) as Average from ratings as r left join brands as b on b.id = r.brand_id left join categories as c on c.id = r.category_id group by b.id order by avg(r.rating) asc limit 10")
	bottom_brands.each do |b|
		brand = "#{b.category.upcase}: #{b.brand.upcase}"
		@bottom_chart.push([brand, b.Average.round(2)])
	end
	erb :index
end

get '/categories/:id' do 
	@brand_spread = Array.new
	@category = DB::Category.find_by_id(params[:id])
	@brands = DB::Brand.find_by_sql("select b.id, b.name, avg(r.rating) as avg_rating, avg(r.ranking) as avg_ranking from brands as b left join ratings as r on r.brand_id = b.id where b.category_id = #{params[:id]} group by r.brand_id order by avg(r.rating) desc")
	@master = DB::Human.find_by_id(@category.master_id)
#	@master = DB::Human.find_by_sql("select h.id, h.first_name, h.last_name from categories as c left join humans as h on h.id = c.master_id where c.id = #{params[:id]}")

	# brand spread
	spread = DB::Rating.find_by_sql("select b.name, avg(r.rating) as avg from ratings as r left join brands as b on b.id = r.brand_id where r.category_id = #{params[:id]} group by r.brand_id order by avg(r.rating) asc")
	spread.each do |s|
		@brand_spread.push([s.name, s.avg.round(2)])
	end
	erb :category
end

get '/humans/:id' do 
	@category_points = Array.new
	@human = DB::Human.find_by_id(params[:id])
	@favorites = DB::Human.find_by_sql("select c.id as category_id, b.id as brand_id, c.name as category, b.name as brand, r.rating from ratings as r left join brands as b on r.brand_id = b.id left join categories as c on c.id = r.category_id where r.ranking = 1 and human_id = #{params[:id]} order by c.id asc")
	@least_favorites = DB::Human.find_by_sql("select distinct c.id as category_id, b.id as brand_id, c.name as category, b.name as brand, r.rating from categories as c left join brands as b on r.brand_id = b.id left join ratings as r on c.id = r.category_id where r.human_id = #{params[:id]} and r.ranking in (select max(ranking) from ratings where category_id = c.id and human_id = #{params[:id]} order by ranking desc limit 1) order by c.id asc")
	@heatmap = DB::Human.find_by_sql("select category_id, min(rating) as min, max(rating) as max from ratings where human_id = #{params[:id]} group by category_id order by category_id asc")
	@master_stats = DB::Category.find_by_sql("select c.id, c.name, avg(r.rating) as avg from categories as c left join ratings as r on r.category_id = c.id where c.master_id = #{@human.id} group by c.id, c.name")
	@scorecard = DB::Rating.find_by_sql("select c.id as category_id, b.id as brand_id, b.name as brand, c.name as category, r.rating, r.ranking from ratings as r left join brands as b on b.id = r.brand_id left join categories as c on c.id = r.category_id where r.human_id = #{params[:id]} order by c.id")

	# points calculations
	points = DB::Rating.find_by_sql("select c.name, sum(r.rating) as points from ratings as r left join categories as c on c.id = r.category_id group by c.name order by sum(r.rating) asc")
	points.each do |p|
		@category_points.push([p.name, p.points])
	end
	erb :human
end

get '/brands/:id' do 
	@ratings = Array.new
	@brand = DB::Brand.find_by_sql("select b.id, b.name, avg(r.rating) as avg_rating, avg(r.ranking) as avg_ranking, sum(r.rating) as sum_rating, c.name as category, c.id as category_id from brands as b left join ratings as r on r.brand_id = b.id left join categories as c on c.id = b.category_id where b.id = #{params[:id]} group by r.brand_id order by avg(r.rating) desc").first
	@category = DB::Brand.where(category_id: @brand.category_id).count

	# RATINGS BAR CHART
	ratings_chart = DB::Rating.find_by_sql("select h.first_name, r.rating from ratings as r left join humans as h on h.id = r.human_id where r.brand_id = #{params[:id]} order by r.rating desc")
	ratings_chart.each do |c|
		@ratings.push([c.first_name, c.rating])
	end

	# RANKINGS CHART
	@rankings = DB::Rating.find_by_sql("select h.first_name, r.rating, r.ranking, r.human_id from ratings as r left join humans as h on h.id = r.human_id where r.brand_id = #{params[:id]} order by r.ranking asc")

	erb :brand
end

# releasing connection because thin and activerecord are assholes
after do
  ActiveRecord::Base.connection.close
end
