# shop.rb - the Shop
# Online.sg #7 Sample code
# Author: Sora Harakami
# Licence: Creative Commons 3.0 BY


require 'rubygems'
require 'sinatra'
require 'activerecord'
require 'haml'


####### Open the database #######

ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :dbfile => "shop.sqlite3"
)

#################################

####### Define models #######

class Item < ActiveRecord::Base
    has_many :prices
    has_many :sales

    def latest_price
        self.prices[self.prices.length - 1]
    end

    def remain_stock
        self.sales[self.sales.length - 1]
    end
    
    def sale_count(p=nil)
        return self.stock - self.remain_stock.remain if p.nil?
        return sale_count_price(p) if p.kind_of?(Price)
        return sale_count_sale(p) if p.kind_of?(Sale)
        raise ArgumentError, "p is not Price or Sale"
    end

    def sale_count_price(p)
        raise ArgumentError, "p is not Price" unless p.kind_of?(Price)
        i = self.prices.index(p)
        raise ArgumentError, "p is not " if i.nil?
        n = self.prices[i + 1]
        if n.nil?
            f = self.sales.find(:all,:conditions => ["created_at >= ?",p.created_at])
            return 0 if f.length <= 0
        else
            f = self.sales.find(:all,:conditions => ["created_at >= :fir AND created_at < :las",{:fir => p.created_at,:las => n.created_at}])
        end
        if f.length > 1
            return f[0].remain - f[f.length - 1].remain
        elsif self.sales.length > 1
            return self.sales[self.sales.index(f[0])-1].remain - f[0].remain
        else
        return 0
        end
    end

    def sale_count_sale(p)
        raise ArgumentError, "p is not Sale" unless p.kind_of?(Sale)
        i = self.sales.index(p)
        n = i <= 0 ? p.remain : self.sales[i - 1].remain
        return n - p.remain
    end

    def sale_amount(p=nil)
        if p.nil?
            a = 0
            self.sales.each do |p2|
                a += sale_amount(p2)
            end
            return a
        else
            return p.kind_of?(Price) ? sale_amount_price(p) : sale_amount_sale(p)
        end
    end

    def sale_amount_price(p)
        raise ArgumentError unless p.kind_of?(Price)
        return self.sale_count(p) * p.price
    end

    def sale_amount_sale(p)
        raise ArgumentError unless p.kind_of?(Sale)
        return self.sale_count(p) * self.price_at_time(p)
    end

    def price_at_time(p)
        raise ArgumentError, "p is not Sale or Price" unless p.kind_of?(Sale) || p.kind_of?(Price)
        time = p.created_at
        return self.prices.find(:last,:conditions => ["created_at <= ?",time]).price
    end

    def self.all_amount
        amount = 0
        self.all.each do |i|
            amount += i.sale_amount
        end
        return amount
    end
end

class Price < ActiveRecord::Base
    belongs_to :item
end

class Sale < ActiveRecord::Base
    belongs_to :item
end

#################################

set :views, File.dirname(__FILE__) + '/templates'
get '/' do
    @amount = Item.all_amount
    haml :index
end

get '/item/:item/destroy' do
    pass if params[:item] == 'new'
    unless params[:confirm]
        @cjump = '/item/'+params[:item]+'/destroy'
        haml :confirm
    else
        Item.delete(params[:item].to_i)
        redirect '/item'
    end
end

get '/item/:item/edit' do
    pass if params[:item] == 'new'
    @item = Item.find_by_id(params[:item].to_i)
    haml :item_edit
end

post '/item/:item/edit' do
    pass if params[:item] == 'new'
    item = Item.find_by_id(params[:item].to_i)
    item.name = params[:name]
    item.stock = params[:stock].to_i
    item.save
    redirect '/item/'+params[:item]
end

get '/item/:item' do
    pass if params[:item] == 'new'
    @amount = Item.all_amount
    @item = Item.find_by_id(params[:item].to_i)
    haml :item
end

get '/item/new' do
    haml :item_new
end

post '/item/new' do
    item = Item.new(
        :name => params[:name],
        :stock => params[:stock].to_i
    )
    item.save
    item.prices.create(
        :price => params[:price].to_i 
    )
    item.sales.create(
        :remain => params[:stock].to_i
    )

    redirect '/item/'+item.id.to_s
end

get '/item' do
    @amount = Item.all_amount
    @items = Item.find(:all)
    haml :items
end

post '/price/:item/new' do
    item = Item.find_by_id(params[:item].to_i)
    item.prices.create(
        :price => params[:price].to_i
    )
    redirect '/item/'+params[:item]
end

get '/price/:item/:price/edit' do
    @item = Item.find_by_id(params[:item].to_i)
    @price = @item.prices[params[:price].to_i]
    haml :price_edit
end

post '/price/:item/:aprice/edit' do
    item = Item.find_by_id(params[:item].to_i)
    price = item.prices[params[:aprice].to_i]
    price.price = params[:price].to_i
    price.save
    redirect '/item/'+params[:item]
end

get '/price/:item/:price/destroy' do
    unless params[:confirm]
        @cjump = '/price/'+params[:item]+'/'+params[:price]+'/destroy'
        haml :confirm
    else
        item = Item.find_by_id(params[:item].to_i)
        item.prices.delete(item.prices[params[:price].to_i])
        item.save
        redirect '/item/'+params[:item]
    end
end

get '/sale/:item/:sale/edit' do
    @item = Item.find_by_id(params[:item].to_i)
    @sale = @item.sales[params[:sale].to_i]
    haml :sale_edit
end

post '/sale/:item/:sale/edit' do
    item = Item.find_by_id(params[:item].to_i)
    sale = item.sales[params[:sale].to_i]
    sale.remain = item.sales[0].remain - params[:sales].to_i
    sale.save
    redirect '/item/'+params[:item].to_s
end

get '/sale/:item/:sale/destroy' do
    unless params[:confirm]
        @cjump = '/sale/'+params[:item]+'/'+params[:sale]+'/destroy'
        haml :confirm
    else
        item = Item.find_by_id(params[:item].to_i)
        item.sales.delete(item.sales[params[:sale].to_i])
        item.save
        redirect '/item/'+params[:item]
    end
end

post '/sale/:item/new' do
    item = Item.find_by_id(params[:item].to_i)
    item.sales.create(
        :remain => params[:remain].empty? ? item.sales[0].remain - params[:sale].to_i : params[:remain].to_i
    )
    redirect '/item/'+params[:item]
end
