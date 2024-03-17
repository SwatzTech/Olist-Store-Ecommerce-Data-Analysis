# An Exploratory Data Analysis on Olist E-commerce Dataset

### About Olist
Olist is a Brazilian e-commerce platform that connects small and medium-sized businesses to customers across Brazil. The platform operates as a marketplace, where merchants can list their products and services and customers can browse and purchase them online.


### Project Overview
To help Olist gain better insights into its e-commerce platform and optimize available opportunities for growth, we will perform an Exploratory Data Analysis, and answer some business questions, thereby providing Insights and recommendations.


### Data Source
contains information on 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil. Its features allow viewing orders from multiple dimensions: from order status, price, payment, and freight performance to customer location, product attributes, and finally reviews written by customers.

[Click Here : LINK TO DATASET](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)


### Tools Used
1. Microsoft Excel - Data Cleaning using Power Query, Data Merging and Basic Dashboard creation
2. MySQL - Data Analysis
3. Power BI - Visualisation using graphs and charts - Dashboard and Reporting
4. Tableau - Visualisation using graphs and charts - Dashboard and Reporting


### Data Cleaning/ Preparation
- Data Loading and Inspection
- Handling missing values
- Removing duplicates
- Deriving data from existing data using Excel formulae
- Formatting the data


### EDA - Exploratory Data Analysis
Exploring Sales data to answer following key business questions:
1) Weekday Vs Weekend (order_purchase_timestamp) Payment Statistics
2) Number of Orders with review score 5 and payment type as credit card.
3) Average number of days taken for order_delivered_customer_date for pet_shop
4) Average price and payment values from customers of sao paulo city
5) Relationship between shipping days (order_delivered_customer_date - order_purchase_timestamp) Vs review scores.
6) Top 10 profit making products
7) Growth of orders over Years and Quarters


### Data Analysis using MySQL
One of the most interesting business question that was queried using MySQL is *Growth of orders over time*
``` MySQL query
with order_growth as (
with order_count_timeline as
(SELECT 
    YEAR(delivery_date) AS del_year,
    QUARTER(delivery_date) AS del_qtr,
    COUNT(order_id) AS num_orders
FROM
    order_delivery_date_view
WHERE
    delivery_date IS NOT NULL
GROUP BY del_year , del_qtr
ORDER BY del_year , del_qtr)
select del_year, del_qtr, num_orders,num_orders-lag(num_orders) over(order by del_year,del_qtr) as growth from order_count_timeline)
select del_year, del_qtr, num_orders, growth,
case when sign(growth) = 1 then 'Increase' when sign(growth) = -1 then 'Decrease' when growth is null then 'Not Known' else 'same' end as 'Increase/Decrease in number of orders' 
from order_growth;
```

### Results/ Findings
The analysis results are summarized as follows:
- The company's sale has been steadily increasing over the years, however there has been a significant dip in sales from September 2018
- Most number of orders are being placed in the 'bed_bath_table' category
- 'Computers' category has the highest AOV
- Most payment has been done via credit cards followed by boletos
- Average delivery days taken for an order delivery is 11 days
- There is a negative corelation between number of days for delivery and review score
- More payments and purchases are being done during weekdays(77%) than weekends

### Recommendations
Based on the above results/ findings, following actions are recommended to improve the performance of Olist:
- Invest in marketing and promotions for Weekend sales
- Provide more offers and discounts for payment methods like debit cards and voucher which are not being used
- Use predictive analysis of demand for inventory management to schedule delivery so that time taken for delivery can be reduced
- Improve pricing and promotional strategy to improve under performing product categories

### Limitations
- Sales data for few important months like October November were missing which usually yields high sales due to Black Friday and hence analysis can be inconsistent

