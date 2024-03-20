/*
	EDA ON OLIST ECOMMERCE DATASET
    Author : Swathi Kota
    GitHub link : https://github.com/SwatzTech/
*/

use olist;

desc orders;
select * from orders limit 5;

desc payments;
select * from payments limit 5;

/*
	1. What is the total revenue generated by Olist, and how has it changed over time?
*/
select round(sum(payment_value)) as total_revenue from payments;

-- SIMPLE ANALYSIS
select year(order_purchase_timestamp) as purchase_year, quarter(order_purchase_timestamp) as quarter, round(sum(payment_value)) as revenue 
from orders o left outer join payments p on o.order_id=p.order_id
group by purchase_year, quarter
order by purchase_year, quarter;

-- DEEPER ANALYSIS
with percent_change_in_Revenue as (
with revenue_change as (
with quarter_wise_growth as (
SELECT 
    YEAR(order_purchase_timestamp) AS purchase_year,
    QUARTER(order_purchase_timestamp) AS quarter,
    ROUND(SUM(payment_value)) AS revenue
FROM
    orders o
        LEFT OUTER JOIN
    payments p ON o.order_id = p.order_id
GROUP BY purchase_year , quarter
ORDER BY purchase_year , quarter)
select purchase_year, quarter, revenue, (revenue - lag(revenue) over(order by purchase_year, quarter)) as change_in_Revenue
from quarter_wise_growth)
select purchase_year, quarter, revenue, change_in_Revenue, concat(round((abs(change_in_Revenue)/revenue)*100,2),'%') as percent_change,
case when change_in_Revenue > 0 then 'INCREASE'
when change_in_Revenue<0 then 'DECREASE'
end as review
from revenue_change)
select purchase_year, concat('Q',quarter) as quarter, revenue, ifnull(concat(percent_change, "  ", review),"") as change_of_revenue_over_time
from percent_change_in_Revenue;

with percent_change_in_Revenue as (
with revenue_change as (
with quarter_wise_growth as (
SELECT 
    YEAR(order_purchase_timestamp) AS purchase_year,
    QUARTER(order_purchase_timestamp) AS quarter,
    MONTH(order_purchase_timestamp) AS month,
    ROUND(SUM(payment_value)) AS revenue
FROM
    orders o
        LEFT OUTER JOIN
    payments p ON o.order_id = p.order_id
GROUP BY purchase_year , quarter, month
ORDER BY purchase_year , quarter, month)
select purchase_year, quarter, month, revenue, (revenue - lag(revenue) over(order by purchase_year, quarter, month)) as change_in_Revenue
from quarter_wise_growth)
select purchase_year, quarter, month, revenue, change_in_Revenue, concat(round((abs(change_in_Revenue)/revenue)*100,2),'%') as percent_change,
case when change_in_Revenue > 0 then 'INCREASE'
when change_in_Revenue<0 then 'DECREASE'
end as review
from revenue_change)
select purchase_year, concat('Q',quarter) as quarter, month, revenue, ifnull(concat(percent_change, "  ", review),"") as change_of_revenue_over_time
from percent_change_in_Revenue;


/*
	2. How many orders were placed on Olist, and how does this vary by month or season?
*/
select count(order_id) as total_orders from orders;

SELECT 
    MONTH(order_purchase_timestamp) AS month,
    monthname(order_purchase_timestamp) as monthname,
    COUNT(payment_value) AS count_of_orders
FROM
    orders o
        LEFT OUTER JOIN
    payments p ON o.order_id = p.order_id
GROUP BY month, monthname
ORDER BY month;

-- Monthly average of orders
select avg(monthly_order_count) as monthly_average_orders from (
select month(order_purchase_timestamp) as month, count(o.order_id) as monthly_order_count
from orders o
LEFT OUTER JOIN
payments p ON o.order_id = p.order_id
group by month) sub;


/*
	3. What are the most popular product categories on Olist, and how do their sales volumes compare to each other?
*/
desc products;
desc order_items;
desc product_category_name_translation;

SELECT 
    product_category_name_english, COUNT(o.order_id) AS num_of_products
FROM
    orders o
        LEFT OUTER JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON p.product_id = oi.product_id
		JOIN
	product_category_name_translation pct ON p.product_category_name = pct.product_category_name
GROUP BY product_category_name_english
ORDER BY num_of_products DESC
LIMIT 10;


/*
	4. What is the average order value (AOV) on Olist, and how does this vary by product category or payment method?
*/

-- PRODUCT CATEGORY
SELECT 
    product_category_name_english,
    ROUND(SUM(payment_value) / COUNT(pay.order_id), 2) AS AOV
FROM
    payments pay
        JOIN
    order_items oi ON pay.order_id = oi.order_id
        JOIN
    products p ON p.product_id = oi.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
GROUP BY product_category_name_english
ORDER BY AOV DESC;

-- PAYMENT TYPE
select payment_type, round(sum(payment_value) / count(pay.order_id),2) as AOV from 
    payments pay 
where payment_type <> "not_defined"
group by payment_type
order by AOV desc;


/*
	5. How many sellers are active on Olist, and how does this number change over time?
*/
desc sellers;
desc order_items;

select count(distinct seller_id) as total_sellers_registered from sellers;

# Top 10 sellers who sold the highest number of products
select distinct seller_id as seller, count(order_id) as items_sold 
from order_items join orders using (order_id)
group by seller
order by items_sold desc
limit 10;

select seller_id, count(order_id) as seller_orders from order_items
group by seller_id
order by seller_orders desc;

-- Change/Growth of sellers over 3 months / quarter
with monthly_active_sellers as(
SELECT 
    YEAR(order_purchase_timestamp) AS year,
    QUARTER(order_purchase_timestamp) AS qtr,
    MONTH(order_purchase_timestamp) AS month,
    COUNT(DISTINCT seller_id) AS active_sellers
FROM
    orders
        JOIN
    order_items USING (order_id)
        JOIN
    sellers USING (seller_id)
WHERE seller_id IS NOT NULL
GROUP BY year , qtr , month
ORDER BY year , qtr , month)
select year, month, qtr, active_sellers as monthly_active_sellers, 
sum(active_sellers) over(partition by year, qtr rows between unbounded preceding and current row) as quarter_wise_growth_of_sellers
from monthly_active_sellers;


-- Change of sellers in 6 months
with half_yearly_sellers as(
with monthly_active_sellers as(
SELECT 
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp) AS month,
    COUNT(DISTINCT seller_id) AS active_sellers
FROM
    orders
        JOIN
    order_items USING (order_id)
        JOIN
    sellers USING (seller_id)
WHERE seller_id IS NOT NULL
GROUP BY year , month
ORDER BY year , month)
select year, month, active_sellers as monthly_active_sellers, 
ntile(2) over(partition by year order by month) as period from monthly_active_sellers)
select year, month, monthly_active_sellers, 
sum(monthly_active_sellers) over(partition by year, period rows between unbounded preceding and current row) as semi_annual_growth_of_sellers
from half_yearly_sellers;


/*
	6. How many customers have made repeat purchases on Olist, and what percentage of total sales do they account for?
*/

desc orders;
desc customers;
desc payments;

-- Number of repeat customers
select count(distinct customer_unique_id) as total_repeat_customers from(
select customer_unique_id, count(order_id) as num_of_repeat_purchases
from orders join customers using (customer_id)
group by customer_unique_id
having num_of_repeat_purchases>1) rept_cust;

-- percentage contribution of repeat customers to total sales
with rept_cust AS(
select sum(payment_value) as rpt_customers_revenue
from payments join orders using (order_id)
join customers using (customer_id)
where customer_unique_id in(
select customer_unique_id from(
select customer_unique_id, count(order_id) as repeat_purchase
from customers join orders using (customer_id)
group by customer_unique_id
having repeat_purchase > 1)sub)),
total_cust_rev AS(
select sum(payment_value) as total_revenue from payments
) select round((rpt_customers_revenue/total_revenue)*100, 2) as rept_cust_sales_percentage
from rept_cust CROSS JOIN total_cust_rev;

/*
	7. What is the distribution of seller ratings on Olist, and how does this impact sales performance?
*/

desc sellers;
desc reviews;
desc order_items;
	
		with review_distribution AS (
			select distinct review_score, 
				count(distinct seller_id) as num_of_sellers, 
				count(order_id) as num_of_orders, 
				round(sum(payment_value),2) as total_revenue
				from sellers join order_items using (seller_id)
				join reviews using (order_id)
				join payments using(order_id)
				group by review_score),
		total_reviewed_sellers AS (
		select sum(num_of_sellers) as total_sellers 
		from review_distribution)
		select review_score, num_of_sellers, 
		concat(round((num_of_sellers/total_sellers)*100,2),' %') as distribution_of_seller_ratings, 
		num_of_orders, total_revenue,
        round((total_revenue/num_of_orders),2) as AOV
		from review_distribution cross join total_reviewed_sellers;


/*
	8. What is the average order cancellation rate on Olist, and how does this impact seller performance?
*/

desc orders;
select distinct order_status from orders;

with total as (
select count(order_id) as total_orders from orders), cancelled as (
select count(order_id) as cancelled_orders from orders where order_status='canceled')
select total_orders, cancelled_orders, round((cancelled_orders/total_orders)*100,2) as cancellation_percentage
from total cross join cancelled;

/*
	9. What are the top-selling products on Olist, and how have their sales trends changed over time?
*/

desc products;
desc order_items;
desc product_category_name_translation;

select *, case when num_of_orders=change_in_orders then 'no change' 
when change_in_orders>0 then 'increase' 
when change_in_orders<0 then 'decrease' end as review
 from (
select *, (num_of_orders - ifnull(lag(num_of_orders) over(partition by product_category_name_english order by year), 0)) as change_in_orders 
from (
select *, dense_rank() over(partition by year order by num_of_orders desc) as rnk from (
select year(order_purchase_timestamp) as year, product_category_name_english, count(order_item_id) as num_of_orders
from order_items join products using (product_id)
join orders using (order_id)
join product_category_name_translation using (product_category_name)
group by year, product_category_name_english) sub)sub2
where rnk<=10) sub3;

/*
	10. Which payment methods are most commonly used by Olist customers, and how does this vary by product category or geographic region?
*/
desc payments;

-- total payment method distribution
with payment_method_evaluation AS(
select distinct payment_type, count(order_id) over(partition by payment_type) as count_per_payment_method,
count(order_id) over() as total_payments
from orders left join payments using (order_id))
select payment_type, count_per_payment_method, 
concat(round((count_per_payment_method/total_payments)*100,2),' %') as payment_distribution
from payment_method_evaluation
where payment_type is not null or payment_type<>'undefined';

-- payment method type by product category
with payment_method_evaluation AS(
select distinct product_category_name_english as product_category, payment_type, 
count(order_id) over(partition by product_category_name,payment_type) as count_per_category_payment_method,
count(order_id) over() as total_payments
from orders left join payments using (order_id)
join order_items using(order_id)
join products using (product_id)
join product_category_name_translation using (product_category_name))
select product_category, payment_type, count_per_category_payment_method, 
concat(round((count_per_category_payment_method/total_payments)*100,2),' %') as payment_distribution
from payment_method_evaluation
where payment_type is not null or payment_type<>'undefined' or product_category<>'undefined'
order by product_category, count_per_category_payment_method desc;

-- payment method type by customer city
with payment_method_evaluation AS(
select distinct customer_city as city, payment_type, 
count(order_id) over(partition by customer_city,payment_type) as count_per_city_payment_method,
count(order_id) over() as total_payments
from orders left join payments using (order_id)
join customers using (customer_id))
select city, payment_type, count_per_city_payment_method, 
concat(round((count_per_city_payment_method/total_payments)*100,2),' %') as payment_distribution
from payment_method_evaluation
where payment_type is not null or payment_type<>'undefined'
order by city, count_per_city_payment_method desc;


/*
	11. Which product categories have the highest profit margins on Olist, 
    and how can the company increase profitability across different categories?
*/
desc order_items;
desc payments;

WITH prod_category_calculations AS (
WITH order_calculations AS (
select o.order_id, payment_value as revenue, round((payment_value-price+freight_value), 2) as profit
from orders o left join order_items oi using(order_id)
join payments using (order_id)	
)
select product_category_name_english as `Product Category`, 
round(sum(revenue),2) as `Total Revenue`, round(sum(profit),2) as `Total Profit`
from order_calculations join order_items using (order_id)
join products using (product_id)
join product_category_name_translation using (product_category_name)
group by product_category_name_english)
select *, round((`Total Profit`/`Total Revenue`)*100, 2) as `Profit Margin`
from prod_category_calculations
order by `Profit Margin` desc;

/* 	
	12. Relationship between shipping days Vs review scores.
*/

select round(avg(datediff(order_delivered_customer_date, order_purchase_timestamp))) as average_shipping_days, review_score
from orders join reviews using(order_id)
where order_delivered_customer_date is not null and
order_purchase_timestamp is not null
group by review_score
order by review_score;