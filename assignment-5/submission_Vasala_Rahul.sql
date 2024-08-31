/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
  
  
/*
Approach: 
 grouping the data with state attribute and 
displaying the data in descending order */

SELECT 
	state, 
    count(customer_id) as Num_customers
FROM customer_t
GROUP BY state
ORDER BY Num_customers DESC;

/*
Observations: 
1. Only top 10-15 states have high Number of customers
2. California, Texas, Florida, New York - These states have highest share of customers
3. More than 50% of the states have very less customer count
4. About 18 states have customer number < 10
*/


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */


/* Approach-1:
Common table Expression is used to assign the rating number to data
The CTE is used to Extract the average rating using aggregate function AVG and 
Grouping by quarter_number 
*/

WITH ratings_table AS
(
	SELECT
		order_id,
        quarter_number,
        CASE WHEN customer_feedback = 'Very Bad' THEN 1
			 WHEN customer_feedback = 'Bad' THEN 2
             WHEN customer_feedback = 'Okay' THEN 3
             WHEN customer_feedback = 'Good' THEN 4
             WHEN customer_feedback = 'Very Good' THEN 5
             END as rating
	FROM order_t        
)
SELECT 
	quarter_number,
    AVG(rating) AS avg_rating
FROM ratings_table
GROUP BY quarter_number
ORDER BY quarter_number;

/* Approach-2: 
Using the 'CASE' to convert the feedback to numbers,
grouping the data with Quarter Number and 
displaying the data in Quarter Order */

SELECT 
	quarter_number AS Quarter, 
    avg(CASE WHEN customer_feedback = 'Very Bad' THEN 1
			 WHEN customer_feedback = 'Bad' THEN 2
             WHEN customer_feedback = 'Okay' THEN 3
             WHEN customer_feedback = 'Good' THEN 4
             WHEN customer_feedback = 'Very Good' THEN 5
             END) as Avg_rating
FROM order_t
GROUP BY quarter_number
ORDER BY Quarter;

/*
Observations: 
1. The Average customer rating is decreasing quarter over quarter
2. The Rate of decrease also Increasing over quarter
(i.e., 1st to 2nd quarter - ~0.2. 2nd to 3rd quarter ~0.4, 3rd to 4th quarter ~0.56) 
*/







-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.*/
      
      
/*
Approach-1:
two Common Table Expressions were created, 
First to count the feedback ratings for each quarter
Second to count the total ratings for each quarter
then percentage rating is calculated by joining 2 CTE.
*/

WITH cust_feedback AS
(
	SELECT 
		quarter_number,
        customer_feedback,
        COUNT(order_id) as num_rating
	FROM order_t
    GROUP BY quarter_number, customer_feedback
    ORDER BY quarter_number, customer_feedback
),
total_ratings AS
(
	SELECT
		quarter_number,
        count(order_id) as total_rating
	FROM order_t
    GROUP BY quarter_number
    ORDER BY quarter_number
)
SELECT 
	cf.customer_feedback,
    cf.quarter_number,
    cf.num_rating,
    tr.total_rating,
    (num_rating/total_rating*100) AS per_rating
FROM cust_feedback cf 
INNER JOIN total_ratings tr ON cf.quarter_number = tr.quarter_number
ORDER BY cf.customer_feedback, cf.quarter_number;

 
/* 
Approach-2:
creating the view which puts count of all customer ratings on a particular rating and null on other ratings
then these are grouped to form table with table which consists ratings as columns and quarter as Primary key,
Then the values are converted to Percentages
*/

CREATE OR REPLACE VIEW all_ratings AS
(
	SELECT 
		quarter_number,
		count(customer_id) as very_bad,
		NULL as bad,
		NULL as okay,
		NULL as good,
		NULL as very_good
    FROM order_t
    WHERE customer_feedback = 'Very Bad'
    GROUP BY quarter_number
    
    UNION ALL
    
    SELECT 
		quarter_number,
		NULL as very_bad,
		count(customer_id) as bad,
		NULL as okay,
		NULL as good,
		NULL as very_good
    FROM order_t
    WHERE customer_feedback = 'Bad'
    GROUP BY quarter_number
    
    UNION ALL
    
    SELECT 
		quarter_number,
		NULL as very_bad,
		NULL as bad,
		count(customer_id) as okay,
		NULL as good,
		NULL as very_good
    FROM order_t
    WHERE customer_feedback = 'Okay'
    GROUP BY quarter_number
    
    UNION ALL
    
    SELECT 
		quarter_number,
		NULL as very_bad,
		NULL as bad,
		NULL as okay,
		count(customer_id) as good,
		NULL as very_good
    FROM order_t
    WHERE customer_feedback = 'Good'
    GROUP BY quarter_number
    
    UNION ALL
    
    SELECT 
		quarter_number,
		NULL as very_bad,
		NULL as bad,
		NULL as okay,
		NULL as good,
		count(customer_id) as very_good
    FROM order_t
    WHERE customer_feedback = 'Very Good'
    GROUP BY quarter_number
);
SELECT
	quarter_number, 
    max(very_bad)/(max(very_bad)+max(bad)+max(okay)+max(good)+max(very_good))*100 as Very_Bad_per, 
	max(bad)/(max(very_bad)+max(bad)+max(okay)+max(good)+max(very_good))*100 as Bad_per, 
	max(okay)/(max(very_bad)+max(bad)+max(okay)+max(good)+max(very_good))*100 as Okay_per,
	max(good)/(max(very_bad)+max(bad)+max(okay)+max(good)+max(very_good))*100 as Good_per,
	max(very_good)/(max(very_bad)+max(bad)+max(okay)+max(good)+max(very_good))*100 as Very_Good_per
FROM all_ratings
GROUP BY quarter_number
ORDER BY quarter_number;

/*
Observations:
1. The ratings in 'Very Good', 'Good' category has been consistently reducing
2. The ratings in 'Okay' category has been nearly constant
3. The ratings in 'Bad', 'Very Bad' category has been consistently increasing
4. The above observations shows that quarter over quarter, The performance (wrt customer Rating) is continuously decreasing
*/







---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/



/*
Approach:
joining the order_t table and product_t table on product_id
group by the vehicle_maker
order with number of customers and 
display top 5 records
*/

SELECT 
	p.vehicle_maker,
    count(o.customer_id) as num_customers
FROM order_t o 
LEFT JOIN product_t p USING(product_id)
GROUP BY p.vehicle_maker
ORDER BY num_customers DESC
LIMIT 5;

/*
Observation:
1. The top 5 car_makers are 'Chevrolet', 'Ford', 'Toyota', 'Pontiac', 'Dodge'
*/



-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

/* 
Approach-1:
All the tables are joined on respective id
The Mega table containing all the info of customer, Order, Vehicle is formed
Then Ranking is given using window function by partitioning with state and order by count of orders
then all rows wit rank = 1 is selected
*/

SELECT 
	state,
    vehicle_maker 
FROM
(
	SELECT 
		c.state, 
        p.vehicle_maker, 
        rank() over(PARTITION BY c.state ORDER BY count(o.customer_id) DESC, vehicle_maker) AS rnk
	FROM order_t o 
    LEFT JOIN customer_t c USING(customer_id)
	LEFT JOIN product_t p USING(product_id)
	GROUP BY c.state, p.vehicle_maker
) sales
WHERE rnk=1
ORDER BY state;


/*
Approach - 2:
Sales_table view is created by joining order_t, customer_t, product_t
and selecting state, vehicle maker, count grouping by state and vehicle maker
Amother view named max_table is created by selecting max from sales of sales table view
Now the sales_table row is considered where sales matches with max
*/

CREATE OR REPLACE VIEW sales_table AS
(
	SELECT 
		c.state,
        p.vehicle_maker,
        count(o.customer_id) AS sales
	FROM order_t o 
    LEFT JOIN customer_t c USING(customer_id)
	LEFT JOIN product_t p USING(product_id)
	GROUP BY c.state, p.vehicle_maker
	ORDER BY state, sales DESC
);

CREATE OR REPLACE VIEW max_table AS
(
	SELECT 
		state,
        max(sales) AS max_ 
	FROM sales_table
	GROUP BY state
);

SELECT 
	s.state,
    min(s.vehicle_maker) as vehicle_maker
FROM sales_table s 
LEFT JOIN max_table m ON s.state = m.state
WHERE s.sales = m.max_
GROUP BY s.state
ORDER BY s.state;

/*
Observations:
All the states with highest nmber of selling brands are found, 
If highest sales are equal then alphabetical order of maker name is chosen
*/


-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

/*
Approach:
Grouped the data by quarter_number and fetched quarter_number and num_orders
*/

SELECT 
	quarter_number, 
    count(order_id) AS num_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

/*Observations:
Number of orders has reduced for every quarter
*/




-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/

/* 
Approach-1:
creating CTE quarterly_revenue to calculate the revenue
then another cte to add lag revenue and to calculate the percentage increase/ decrease in revenue
*/

WITH quarterly_revenue AS (
    SELECT 
        quarter_number,
        SUM(vehicle_price) AS total_revenue
    FROM order_t
    GROUP BY quarter_number
),
qoq_revenue AS (
    SELECT
        quarter_number,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY quarter_number) AS prev_quarter_revenue,
        (total_revenue - LAG(total_revenue) OVER (ORDER BY quarter_number)) / LAG(total_revenue) OVER (ORDER BY quarter_number) * 100 AS qoq_percentage_change
    FROM
        quarterly_revenue
)

SELECT
    quarter_number,
    total_revenue,
    prev_quarter_revenue,
    qoq_percentage_change
FROM qoq_revenue;


/*
Approach - 2:
creating the required calculation diretly using window function
*/

SELECT
	quarter_number,
    sum(vehicle_price) AS present_revenue, 
	LAG(sum(vehicle_price),1,NULL) OVER(ORDER BY quarter_number) AS old_revenue,
	(sum(vehicle_price)-(LAG(sum(vehicle_price),1,NULL) OVER(ORDER BY quarter_number)))/(LAG(sum(vehicle_price),1,NULL) over(order by quarter_number))*100 as per_change
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

/*Observations:
The revenue has been continuously reducing quarter over quarter
*/


      
      

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

/*Approach:
Grouped the data by quarter Number
then sum, count aggregation functions are used to fetch the required data
*/

SELECT
	quarter_number,
    sum(vehicle_price) AS revenue,
    count(order_id) AS num_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_Number;

/* Observations:
Revenue and Number of orders were continuously decreasing
*/


-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

/*Approach:
Grouped the data with credit card type and
fetched the required data
*/

SELECT
	c.credit_card_type, 
    AVG(o.discount) AS avg_discount
FROM order_t o 
LEFT JOIN customer_t c ON o.customer_id = c.customer_id
GROUP BY c.credit_card_type
ORDER BY AVG(o.discount) DESC;

/*Observations:
laser card type has the maximum discount with 0.6438 avergae discount
*/


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

/*Approach:
Grouped data by quarter number
found the average of date difference usinf DateDiff function
*/

SELECT 
	quarter_number, 
    AVG(datediff(ship_date, order_date)) AS avg_ship_time
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

/*Observations:
The average time taken to ship the placed order has increased quarter over quarter
*/


-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



