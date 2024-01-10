-- The database contains eight tables:
-- 	Customers: customer data
-- 	Employees: all employee information
-- 	Offices: sales office information
-- 	Orders: customers' sales orders
-- 	OrderDetails: sales order line for each sales order
-- 	Payments: customers' payment records
-- 	Products: a list of scale model cars
-- 	ProductLines: a list of product line categories
-- 
-- How each table links to one other is shown in the Schema Diagram.

-- Below we explore the database and return the total number of rows and columns in each table.

SELECT 'customers' AS name,
                13 AS number_of_attributes,
		  COUNT(*) AS number_of_rows
  FROM customers

 UNION ALL

SELECT 'employees' AS name,
                 8 AS number_of_attributes,
	      COUNT(*) AS number_of_rows
  FROM employees

 UNION ALL

SELECT 'offices' AS name, 
               9 AS number_of_attributes,
	    COUNT(*) AS number_of_rows
  FROM offices
  
 UNION ALL
  
SELECT 'orders' AS name, 
              7 AS number_of_attributes,
	   COUNT(*) AS number_of_rows
  FROM orders

 UNION ALL
  
SELECT 'order details' AS name, 
                     5 AS number_of_attributes,
	          COUNT(*) AS number_of_rows
  FROM orderdetails
 
 UNION ALL
  
SELECT 'payments' AS name, 
                4 AS number_of_attributes,
	     COUNT(*) AS number_of_rows
  FROM payments
  
 UNION ALL
  
SELECT 'products' AS name, 
                9 AS number_of_attributes,
	     COUNT(*) AS number_of_rows
  FROM products
  
 UNION ALL
  
SELECT 'productlines' AS name, 
                    4 AS number_of_attributes,
	         COUNT(*) AS number_of_rows
  FROM productlines;

-- Q1: Which products should we order more/less of? What products are driving revenue and profitability the most?

-- The nested query below provides us with details regarding avgerage monthly orders for a product, and the total_revenue, and total profit of that product till date.
-- We can use this information to make strategic actions on which products need to be ordered and kept in stock. Products with a history of high profits and average monthly orders can be given more focus too
-- Whilst products with less profit and low monthly order volume can be given lesser preference.

WITH
yr_mn
AS (
    SELECT orderNumber,SUBSTR(orderdate,1,7) AS year_month
      FROM orders
     ),
   
orders_per_month
AS (  
    SELECT y.year_month, od.productCode, SUM(quantityOrdered) AS total_ordered
      FROM orderdetails od
      JOIN yr_mn y
        ON od.orderNumber = y.orderNumber
     GROUP BY y.year_month, od.productCode
    ),
	
 avg_orders_per_month
 AS (   -- From this query we can determine the products at the top of the list are ordered in less quantities on average.
     SELECT productCode, ROUND(AVG(total_ordered),2) AS avg_monthly_order
       FROM orders_per_month
      GROUP BY productCode
      ORDER BY avg_monthly_order),
  
 product_revenue_profit 
 AS (
     SELECT od.productCode, ROUND(SUM(od.quantityOrdered*od.priceEach),2) AS total_revenue, ROUND(SUM(od.quantityOrdered*od.priceEach)- SUM(od.quantityOrdered)*buyPrice,2) AS total_profit
       FROM orderdetails od
       JOIN products p
         ON od.productCode = p.productCode
      GROUP BY od.productCode
      ORDER BY total_profit DESC
    )
 
SELECT a.productCode,a.avg_monthly_order,p.total_revenue,p.total_profit
  FROM avg_orders_per_month a
  JOIN product_revenue_profit p
    ON a.productCode = p.productCode
 ORDER BY p.total_profit DESC;
 
-- Q2: How should we tailor marketing and communications to drive loyalty and improve customer retention?

-- Now we will focus on finding which customers are our VIP customers are which customers are less engaged.
-- With this information the marketing team can use targeted marketing tactics such as loyalty programs for the VIP customers and focus on other campaigns for the less engaged customers.

WITH total_order_table
  AS (SELECT o1.orderNumber, SUM(o1.quantityOrdered * o1.priceEach) AS order_total, c.customerName, o2.customerNumber 
    FROM orderdetails o1
	JOIN orders o2
	  ON o1.orderNumber = o2.orderNumber
	JOIN customers c
	  ON o2.customerNumber = c.customerNumber
   GROUP BY o1.orderNumber
   ORDER BY order_total DESC)
   
   SELECT customerNumber, customerName, SUM(order_total) AS customers_total_order
     FROM total_order_table
	 GROUP BY customerNumber
	 ORDER BY customers_total_order DESC
	 LIMIT 5;
	 
-- The above query provides us with a table that shows us which customers are bringing in the most revenue. However for the marketing department it could also be useful to focus on customers that are brining in the most profit. 
-- Lets try to see which customers bring in the most profit for the organisation and rank them accordingly.

SELECT o.customerNumber, c.customerName, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
  JOIN customers c
    ON o.customerNumber = c.customerNumber
 GROUP BY o.customerNumber
 ORDER BY profit DESC
 LIMIT 5;

 
 -- From comparing the two queries above we can wee the top 5 customers by revenue are similar to the top 5 customers by profit.
 -- This means we can run VIP loyalty programs based on the companies discretion on whether we want to focus on revenue or profit as a top metric to label VIP customers.
 -- Alternatively, we can also look at the bottom 5 customers of the list by removing 'DESC' from the code above to analyse the customers driving least revenue and profit and find ways for them to re-engage
 
 
-- Q3: How much can we spend on acquiring new customers?

-- To answer this we should look at how much lifetime value each customer brings into the company.
  
  WITH
  profit_gen_table AS (
	SELECT os.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS prof_gen  
      FROM products pr
	  JOIN orderdetails od
	    ON pr.productCode = od.productCode
	  JOIN orders os
	    ON od.orderNumber = os.orderNumber
     GROUP BY os.customerNumber
  )
   SELECT AVG(pg.prof_gen) AS lyf_tym_val
     FROM profit_gen_table pg;
	 
-- The above query tells us the lifetime value (in terms of profit) an avergare customer brings to the company is around 39,000 USD.
-- As a company it is advisable to not spend over this amount per customer as we will not be profitable. Using marketing techniques to acquire the most amount of customers for the least amount spent is the way forward.
-- As a suggestion social and online platforms have great reach for targetted ads with minimal capital required. Using a chunk of the marketing budget to focus on this would be priority.