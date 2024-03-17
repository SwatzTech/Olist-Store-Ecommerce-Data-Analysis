use olist;

/* 	
	KPI 1
	Weekday Vs Weekend (order_purchase_timestamp) Payment Statistics
*/

create view kpi1 as 
select case when dayofweek(order_purchase_timestamp) in (1,7) then 'Weekend'
else 'Weekday' end as day_type, 
concat(round(sum(payment_value)/1000000,2),'M') as sales
from orders join payments using(order_id) 
group by day_type;

# Total weekly sales - weekend + weekday
select concat(round(sum(payment_value)/1000000,2),'M') as total_week from payments; # '16008872.1199987'

select * from kpi1;


/* 	
	KPI 2
	Number of Orders with review score 5 and payment type as credit card.
*/

create view kpi2 as
select review_score, count(distinct r.order_id) as num_of_orders 
from reviews r join payments using(order_id)
where payment_type='credit_card' and review_score=5
group by review_score 
order by review_score;

select * from kpi2;

# All review scores Vs num of orders
select review_score, count(distinct r.order_id) as num_of_orders 
from reviews r join payments using(order_id)
where payment_type='credit_card'
group by review_score 
order by review_score;


/* 	
	KPI 3
	Average number of days taken for order_delivered_customer_date for pet_shop
*/

create view kpi3 as
select product_category_name, round(avg(ifnull(datediff(order_delivered_customer_date, order_purchase_timestamp),0))) as avg_num_days_for_delivery 
from orders o join order_items oi using (order_id) join products using(product_id)
where product_category_name = 'pet_shop'
group by product_category_name;

select * from kpi3;


/* 	
	KPI 4
	Average price and payment values from customers of sao paulo city
*/

create view kpi4 as 
select round(avg(price),2) as avg_price, round(avg(payment_value),2) as avg_payment_value
from customers join orders using(customer_id) join order_items using(order_id) join payments using(order_id) 
where customer_city='sao paulo';
#group by customer_city;

select * from kpi4;



/* 	
	KPI 5
	Relationship between shipping days (order_delivered_customer_date - order_purchase_timestamp) Vs review scores.
*/

create view kpi5 as
select round(avg(datediff(order_delivered_customer_date, order_purchase_timestamp))) as shipping_days, review_score
from orders join reviews using(order_id)
where order_delivered_customer_date is not null and
order_purchase_timestamp is not null
group by review_score
order by review_score;

select * from kpi5;


/* 	
	KPI 6
	Quarter wise growth in number of orders
*/
create view order_delivery_date_view as
select str_to_date(order_delivered_customer_date,'%Y-%m-%d %H:%i:%S') as delivery_date, order_id from orders;

create view kpi6 as 
with order_growth as (
with order_count_timeline as
(select year(delivery_date) as del_year, quarter(delivery_date) as del_qtr, count(order_id) as num_orders
from order_delivery_date_view 
where delivery_date is not null 
group by del_year, del_qtr
order by del_year, del_qtr)
select del_year, del_qtr, num_orders,num_orders-lag(num_orders) over(order by del_year,del_qtr) as growth from order_count_timeline)
select del_year, del_qtr, num_orders, growth,
case when sign(growth) = 1 then 'Increase' when sign(growth) = -1 then 'Decrease' when growth is null then 'Not Known' else 'same' end as 'Increase/Decrease in number of orders' 
from order_growth;

select * from kpi6;



/* 	
	KPI 7
	Top 10 Profit making product categories
*/

create view kpi7 as
select product_category_name, round(sum(payment_value - price)) as profit 
from products left join order_items using (product_id)
join payments using (order_id)
where product_category_name is not null
and payment_value is not null and price is not null
group by product_category_name
order by profit desc
limit 10;

select * from kpi7;


# KPI cards

-- 1. Total count of orders
select count(order_id) from orders;

-- 2. Total number of active cutomers
select count(distinct customer_id) from orders;

# select count(distinct o.customer_id) from customers c join orders o using(customer_id);

-- 3. Total Sales
select concat(round(sum(payment_value)/1000000,2),' M') as total_sales from payments;

-- 4. Total Profit
select concat(round(sum(payment_value - price)/1000000,2),' M') as total_profit from order_items join payments using (order_id);