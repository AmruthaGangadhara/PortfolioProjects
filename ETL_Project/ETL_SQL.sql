-- DROP TABLE df_orders

-- CREATE TABLE df_orders
-- (order_id INT PRIMARY KEY,
-- order_date DATE,
-- ship_mode VARCHAR(20),
--  segment VARCHAR(20),
--  country VARCHAR(20),
--  city VARCHAR(20),
--  state VARCHAR(20),
--  postal_code VARCHAR(20),
--  region VARCHAR(20),
--  category VARCHAR(20),
--  sub_category VARCHAR(20),
--  product_id VARCHAR(50),
--  quantity INT,
--  discount DECIMAL(7,2),
--  sale_price DECIMAL(7,2),
--  profit DECIMAL(7,2))
 
 SELECT * FROM df_orders;
 
 --Question 1: Find top 10 revenue generating products
 SELECT product_id,SUM(sale_price) sales
 FROM df_orders
 GROUP BY product_id
 ORDER BY 2 DESC
 LIMIT 10
 
 --Question 2: Find top 5 selling products in each region
 with region_sales as (SELECT region,
 product_id,
 SUM(sale_price) sales,
 DENSE_RANK() OVER(PARTITION BY region ORDER BY SUM(sale_price) DESC ) rn
 FROM df_orders
 GROUP BY 1,2)
 
 SELECT region,
 product_id,
 sales,
 rn
 FROM region_sales
 WHERE rn<=5
 
 --Question 3: Find Month On Month Growth Comparison for 2022 and 2023 sales Ex: Jan 2022 and Jan 2023
 
--  with cte as (SELECT DATE_PART('year',order_date) as year,
--  DATE_PART('month',order_date) as month,
--  sum(sale_price) sale_price
--  FROM df_orders
--  GROUP BY 1,2
--  ORDER BY 1,2)
 
--  SELECT t1.year, t1.month, t1.sale_price,t2.year, t2.month, t2.sale_price
--  FROM cte t1 inner join cte t2 on
--  t2.year>t1.year and t2.month=t1.month
 
  
 with cte as (SELECT DATE_PART('year',order_date) as year,
 DATE_PART('month',order_date) as month,
 sum(sale_price) sale_price
 FROM df_orders
 GROUP BY 1,2
 ORDER BY 1,2),
 
 monthly_sales as (SELECT month,
 sum(CASE WHEN year='2022' THEN sale_price else 0 end) as sales_2022 ,
 sum(CASE WHEN year='2023' THEN sale_price else 0 end) as sales_2023
 FROM cte
 GROUP BY 1
 ORDER BY 1)
 
 SELECT month,
 sales_2022,
 sales_2023,
 CONCAT(ROUND((((sales_2023-sales_2022)/sales_2022)*100 ),2),'%') as growth_percentage
 FROM monthly_sales
 
 
 --Question 4: For each category, which month had highest sales
 
 WITH cte as (SELECT category,
 to_char(order_date,'yyyy-mm') as order_ym,
 sum(sale_price) sales,
 dense_rank() over(partition by category order by sum(sale_price) DESC) as rn
 FROM df_orders
 group by 1,2)
 
 SELECT category,
 order_ym,
 sales
 FROM cte
 WHERE rn=1
 
 
 --Question 5: Which sub category had highest growth by profit in 2023 compared to 2022


 WITH CTE AS (SELECT sub_category,
 SUM(CASE WHEN date_part('year',order_date)='2022' THEN profit else 0 end) AS profit_2022,
 SUM(CASE WHEN date_part('year',order_date)='2023' THEN profit else 0 end) AS profit_2023
 FROM df_orders
 GROUP BY 1
ORDER BY 2),

rank_sub as (SELECT sub_category,
profit_2023-profit_2022,
dense_rank() over(ORDER BY profit_2023-profit_2022 DESC ) rn
FROM CTE )

select sub_category
from rank_sub
where rn=1
