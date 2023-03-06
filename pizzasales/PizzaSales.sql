--Create Table: pizza_types
CREATE TABLE pizza_types(
pizza_type_id varchar(50) PRIMARY KEY,
name varchar(200),
category varchar(30),
ingredients varchar(300));

--Create Table: pizzas
CREATE TABLE pizzas(
pizza_id VARCHAR(50) PRIMARY KEY,
pizza_type_id varchar(50),
size varchar(3),
price numeric(10,2),
name varchar(200),
CONSTRAINT fk_pizza_type_id FOREIGN KEY (pizza_type_id) REFERENCES pizza_types(pizza_type_id));

--Create Table: orders
CREATE TABLE orders(
order_id INT PRIMARY KEY,
date_of_order date,
time_of_order time);

--Create Table: order_details
CREATE TABLE order_details(
	order_details_id int PRIMARY KEY,
	order_id INT,
	pizza_id VARCHAR(50),
	quantity int,
	CONSTRAINT fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id),
	CONSTRAINT fk_pizza_id FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id));
	
	
--Lets copy data to the tables from csv files

COPY pizza_types FROM 'C:\Users\amrut\OneDrive\Documents\SQL\project2\pizzasales\pizza_types.csv' DELIMITER ',' CSV HEADER;
COPY pizzas FROM 'C:\Users\amrut\OneDrive\Documents\SQL\project2\pizzasales\pizzas.csv' DELIMITER ',' CSV HEADER;
--While I tried to copy data from table pizzas, the below error occurred.
/*ERROR:  missing data for column "name"
CONTEXT:  COPY pizzas, line 2: "bbq_ckn_s,bbq_ckn,S,12.75"
SQL state: 22P04*/
--Seems like I had added an extra column while creating the table. Let's go ahead and delete the column

ALTER TABLE pizzas
DROP COLUMN name;
--Once I dropped the column,  I was able to copy the data successfully


COPY orders FROM 'C:\Users\amrut\OneDrive\Documents\SQL\project2\pizzasales\orders.csv' DELIMITER ',' CSV HEADER;
COPY order_details FROM 'C:\Users\amrut\OneDrive\Documents\SQL\project2\pizzasales\order_details.csv' DELIMITER ',' CSV HEADER;

Lets check data in all the tables

SELECT * FROM orders
SELECT * FROM order_details
SELECT * FROM pizzas
SELECT * FROM pizza_types

--All the data looks good. Lets go ahead and analyse pizza sales for the store


--Lets check the number of items in each order and see which order had the most and least number of items

--order_id with most number of items:
--order_id--18845
--num_items-28
SELECT o.order_id,sum(od.quantity) num_items 
FROM order_details od
INNER JOIN orders o on
od.order_id=o.order_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


--order_id with least number of items:
--order_id--4790
--num_items-1
SELECT o.order_id,sum(od.quantity) num_items 
FROM order_details od
INNER JOIN orders o on
od.order_id=o.order_id
GROUP BY 1
ORDER BY 2 
LIMIT 1;

--Which pizza category was the most ordered? and the least ordered?

--classic pizza is the most ordered pizza

SELECT pt.category pizza_category,SUM(od.quantity) num_pizzas_ordered
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on
pt.pizza_type_id=p.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC 
LIMIT 1;

--What is the name of pizza which was the most ordered? and the least ordered?

-- "The Classic Deluxe Pizza" is the most ordered pizza

SELECT pt.name,SUM(od.quantity) num_pizzas_ordered
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on
pt.pizza_type_id=p.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC 
LIMIT 1;

--which is the least ordered pizza category?

--chicken 
SELECT pt.category pizza_category,SUM(od.quantity) num_pizzas_ordered
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on
pt.pizza_type_id=p.pizza_type_id
GROUP BY 1
ORDER BY 2 
limit 1;


--What is the name of pizza which was the least ordered? and the least ordered?
-- "The Brie Carre Pizza" is the most ordered pizza

SELECT pt.name,SUM(od.quantity) num_pizzas_ordered
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on
pt.pizza_type_id=p.pizza_type_id
GROUP BY 1
ORDER BY 2 
LIMIT 1;


--lets check ingredients on The Classic Deluxe Pizza
SELECT distinct unnest(string_to_array(pt.ingredients,',')) as ingredients
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on
pt.pizza_type_id=p.pizza_type_id
where pt.name='The Classic Deluxe Pizza'

--Lets check the ingredients on Brie caree pizza
--could have also done this using regexp_split

SELECT distinct unnest(string_to_array(pt.ingredients,',')) as ingredients
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on
pt.pizza_type_id=p.pizza_type_id
where pt.name='The Brie Carre Pizza'

--Since we will be using these 4 tables together for most of our analysis, creating a view is better.
CREATE VIEW pizza_sales AS
with cte as (SELECT o.order_id,o.date_of_order,
			 o.time_of_order,od.order_details_id,od.quantity,
			 p.pizza_id,p.size,p.price,
			 pt.pizza_type_id,pt.name,pt.category,pt.ingredients
FROM order_details od INNER JOIN orders o
on o.order_id=od.order_id
INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on
pt.pizza_type_id=p.pizza_type_id			
)
SELECT * FROM cte;

SELECT * FROM pizza_sales;



--lets check sizewise order quantity

--L is the most ordered
--XXL is the least ordered

SELECT size,sum(quantity) total_pizzas_ordered
FROM pizza_sales
GROUP BY 1
ORDER BY 2 DESC

--lets check revenue for each of the pizzas sizewise

--L is the pizza size which contributed the max revenue
--XXL is the one that made the least
SELECT size,sum(price*quantity) total_revenue
FROM pizza_sales
GROUP BY 1
ORDER BY 2 DESC

--Lets analyse sales of diferent category pizzas
--CLASSIC IS THE HIGHEST AND VEGGIE IS THE LOWEST IN TERMS OF REVENUE

SELECT category,sum(price*quantity) revenue
FROM pizza_sales
GROUP BY category
ORDER BY 2 DESC;

--Lets check which pizza contributed to the maximum revenue
--Thai Chicken pizza
SELECT name,SUM(price*quantity) revenue
FROM pizza_sales
GROUP BY 1
ORDER BY 2 DESC
limit 1;


--pizza which performed low in the revenue aspect is brie carre pizza
SELECT name,SUM(price*quantity) revenue
FROM pizza_sales
GROUP BY 1
ORDER BY 2 
limit 1;

--Lets check monthwise sales, the month which had the highest and lowest sales
--month with max sales-july
SELECT lower(left((to_char(date_of_order,'month')),3)) month_of_order,sum(price*quantity) revenue
FROM pizza_sales
group by 1
order by 2 desc
limit 1;


--month with min sales oct
SELECT lower(left((to_char(date_of_order,'month')),3)) month_of_order,sum(price*quantity) revenue
FROM pizza_sales
group by 1
order by 2
limit 1;


--quarter wise sales and max anmd min

SELECT date_part('quarter',date_of_order) quarter,sum(price*quantity) total_revenue
FROM pizza_sales
group by 1
order by 2 desc


--lets rank the pizzas according to the order quantity

SELECT category,name,
sum(quantity) total_pizzas_ordered,rank() over(partition by category order by sum(quantity) desc) pizza_rank
FROM pizza_sales
group by 1,2

--let me check the pizzas which hold the 1st rank in terms of order quantity in each category
with temp as (SELECT category,name,
sum(quantity) total_pizzas_ordered,rank() over(partition by category order by sum(quantity) desc) pizza_rank
FROM pizza_sales
group by 1,2)

SELECT category,name,total_pizzas_ordered,pizza_rank
FROM temp
where pizza_rank=1
ORDER BY 3 DESC


--lets rank the pizzas by category in terms of revenue

SELECT category,name,sum(price*quantity) total_revenue,
dense_rank() over(partition by category order by sum(price*quantity) DESC ) pizza_rank
FROM pizza_sales
GROUP BY 1,2


select max(pizza_rank)
from (SELECT category,name,sum(price*quantity) total_revenue,
dense_rank() over(partition by category order by sum(price*quantity) DESC ) pizza_rank
FROM pizza_sales
GROUP BY 1,2)temp

--Lets get category and the pizza names with highest revenue/rank
with temp2 as(SELECT category,name,sum(price*quantity) total_revenue,
dense_rank() over(partition by category order by sum(price*quantity) DESC ) pizza_rank
FROM pizza_sales
GROUP BY 1,2)
SELECT category,name,total_revenue,pizza_rank
FROM temp2
WHERE pizza_rank=1

--Lets get category wise pizza with the least revenu
with temp2 as(SELECT category,name,sum(price*quantity) total_revenue,
dense_rank() over(partition by category order by sum(price*quantity)  ) pizza_rank
FROM pizza_sales
GROUP BY 1,2)
SELECT category,name,total_revenue
FROM temp2
WHERE pizza_rank=1
ORDER BY 3 


--Let us check the max and min price for each sizes
--XXL is the highest priced
--s is the lowest priced
SELECT size,max(price),min(price)
FROM pizza_sales
GROUP BY 1
ORDER BY 2 DESC,3 DESC;

--size wise max price and the pizza name
with t1 as (SELECT size,max(price) max_price,min(price) min_price
FROM pizza_sales
GROUP BY 1
ORDER BY 2 DESC,3 DESC),
t2 as (SELECT size,price,name
	  FROM pizza_sales
	  )
SELECT distinct t1.size,t1.max_price max_price,t2_max.name pizza_name_max,t1.min_price min_price,t2_min.name pizza_name_min
FROM t1 INNER JOIN t2 t2_max on t1.size=t2_max.size AND t1.max_price=t2_max.price
INNER JOIN t2 t2_min on t1.size=t2_min.size AND t1.min_price=t2_min.price
ORDER BY 2 DESC,4 DESC;

--the above query took a lot of time

SELECT size,max(price) max_price,name max_name
FROM pizza_sales
GROUP BY 1,3)






with t1 as(SELECT p.size,max(p.price) max_price,min(p.price) min_price
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on 
pt.pizza_type_id=p.pizza_type_id
group by 1),
t2 as (SELECT p.size,p.price,pt.name
FROM order_details od INNER JOIN pizzas p on
od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt on 
pt.pizza_type_id=p.pizza_type_id )


SELECT DISTINCT t2.size,t2.price,
CASE WHEN t2.size=t1.size and t2.price=t1.max_price then t2.name end max_pizza_name
FROM t2 INNER JOIN t1 on
t2.size=t1.size and t2.price=t1.max_price
ORDER BY 1;


--lets get the running total of the revenue 

SELECT date_of_order,sum(price*quantity) revenue,
SUM(SUM(price*quantity)) OVER(ORDER BY date_of_order) running_revenue
FROM pizza_sales
GROUP BY 1
ORDER BY 1

--What is the total revenue for each category and size,
--as well as the percentage of revenue for each category and size compared to the total revenue for that day?
with t1 as (SELECT date_of_order,SUM(price*quantity) revenue_day
FROM pizza_sales
GROUP BY 1
ORDER BY 1),
t2 as(SELECT date_of_order,size,SUM(price*quantity) revenue_size
FROM pizza_sales
GROUP BY 1,2
ORDER BY 1)
SELECT t1.date_of_order,t1.revenue_day daily_revenue,t2.size,t2.revenue_size revenue_by_size,
(t2.revenue_size/t1.revenue_day)*100 pizza_size_revenue_share
FROM t1 INNER JOIN t2 ON
t1.date_of_order=t2.date_of_order
ORDER BY 1,4 DESC

OR 

SELECT
  date_of_order,
  category,
  size,
  SUM(price * quantity) AS revenue,
  SUM(SUM(price * quantity)) OVER (PARTITION BY date_of_order) AS total_revenue,
  SUM(price * quantity) / SUM(SUM(price * quantity)) OVER (PARTITION BY date_of_order) AS pct_of_total
FROM pizza_sales
GROUP BY date_of_order, category, size
ORDER BY date_of_order, category, size;

---What is the best-selling pizza for each day, as well as the running total of the quantity sold over time?

SELECT date_of_order,name,SUM(quantity),
SUM(SUM(quantity)) OVER(ORDER BY date_of_order) rolling_quantity
FROM pizza_sales
GROUP BY 1,2
ORDER BY 1,3 DESC



--What is the total quantity of pizzas sold for each day,
--as well as the rolling average over the past 7 days?

SELECT date_of_order,SUM(quantity),AVG(quantity)
FROM pizza_sales
GROUP BY 1
ORDER BY 1



