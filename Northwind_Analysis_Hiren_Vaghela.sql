use northwind;


-- 1.Show all products that are discontinued but still have units in stock. 

SELECT * FROM products;

SELECT productName FROM products
WHERE discontinued = "1" and unitsInStock > 0;

-- 2.Find the top 10 most expensive products that are not discontinued.

SELECT productName,unitPrice FROM products
WHERE discontinued = "0" 
ORDER BY unitPrice DESC LIMIT 10;

-- 3.Display customer names along with the number of distinct countries they belong to. 

SELECT companyName,country , count(distinct(country)) AS no_of_count
FROM customers
GROUP BY companyName,country
ORDER BY no_of_count DESC;

-- 4.Find employees who were hired after 1992 and are older than 50 years (bASed on birthdate).

SET sql_safe_updates = False;

UPDATE employees
SET hireDate = NULL
WHERE hireDate = '00:00.0';

UPDATE employees
SET birthDate = NULL
WHERE birthDate = '00:00.0';

ALTER TABLE employees
MODIFY hireDate Date;

ALTER TABLE employees
MODIFY birthDate Date;

SELECT employeeID,firstName,lAStName
FROM employees
WHERE hireDate > "1992-01-01" and timestampdiff(YEAR,birthDate,CURDATE()) > 50;

-- 5.Show orders that were shipped after the required date. 

SELECT * FROM orders;

UPDATE orders
SET orderDate = NULL 
WHERE orderDate = '00:00.0';

UPDATE orders
SET requiredDate = NULL 
WHERE requiredDate = '00:00.0';

UPDATE orders
SET shippedDate = NULL 
WHERE shippedDate = '00:00.0';

alter table orders
modify orderDate Date,
modify requiredDate Date,
modify shippedDate Date;

SELECT orderID,customerID,shipName 
FROM orders
WHERE shippedDate > requiredDate;

-- 6.Find the total number of orders placed in each quarter of 1996. 

SELECT quarter(orderDate) AS no_quarter,count(orderID) AS no_of_orders
FROM orders
GROUP BY no_quarter;

-- 7.Show the average freight cost per shipper for orders shipped to Germany. 

SELECT shipName,round(avg(freight),2) AS avg_freight FROM orders
WHERE shipCountry = "Germany"
GROUP BY shipName ORDER BY avg_freight DESC;

SELECT s.companyname,avg(freight) FROM orders o JOIN shippers s on o.shipvia=s.shipperid
WHERE o.shipcountry='Germany' GROUP BY s.companyname ;

-- 8.Find customers who have placed orders in all four years (1996, 1997, 1998). 

SELECT customerID,orderDate
FROM orders
WHERE extract(YEAR FROM orderDate) = 1996 and 
	extract(YEAR FROM orderDate) = 1997 and 
	extract(YEAR FROM orderDate) = 1998;

-- 9.Display product names that contain both 'ch' and 'ee' in their name. 

SELECT productName FROM products
WHERE productName like "%ch%" and productName like "%ee%";

-- 10.Show the total revenue generated FROM each category in 1997. 

SELECT c.categoryName , sum(p.quantityPerUnit * p.unitPrice) AS revenue
FROM categories c 
JOIN products p
on c.categoryID = p.categoryID
JOIN orderdetails AS od
on p.productID = od.productID
JOIN orders AS  o
on od.orderID = o.orderID
WHERE o.orderDate  = 1997
GROUP BY c.categoryName;



-- 11.Find the employee who handled the highest number of orders in 1996. 

SELECT employeeID,count(*) AS no_of_count
FROM orders
WHERE orderDate = 1996
GROUP BY employeeID 
ORDER BY no_of_count DESC;

-- 12.Show all orders WHERE freight is higher than the average freight of all orders. 

SELECT orderID , freight 
FROM orders
WHERE freight > (SELECT AVG(freight) FROM orders) 
ORDER BY freight DESC;

-- 13.Find products that have never been ordered by customers FROM France. 

SELECT p.productID, p.productName
FROM products p
WHERE p.productID NOT IN (
    SELECT od.productID
    FROM customers c
    JOIN orders o
        ON c.customerID = o.customerID
    JOIN orderdetails od
        ON o.orderID = od.orderID
    WHERE c.country = 'France'
);

-- 14.Display the top 5 customers by total spending in the year 1997. 

SELECT c.companyName , round(sum(od.unitPrice * od.quantity),2) AS spend 
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
WHERE o.orderDate = 1997
GROUP BY c.companyName 
ORDER BY spend DESC;

-- 15.Show the difference between order date and shipped date for all orders (in days). 

SELECT DATEDIFF(shippedDate,orderDate) AS no_of_days
FROM orders;

-- 16.Find customers who placed more than 20 orders but have never ordered 'Chai'. 

SELECT c.companyName , count(distinct(o.orderID)) no_of_orders
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
JOIN products AS p
on od.productID = p.productID
WHERE p.productName != "Chai"
GROUP BY c.companyName 
HAVING no_of_orders > 20
ORDER BY no_of_orders DESC;


SELECT c.companyName,COUNT( o.orderID) AS no_of_orders
FROM customers c
JOIN orders o
ON c.customerID = o.customerID
WHERE c.customerID NOT IN (
    SELECT c.customerID
    FROM customers c
    JOIN orders o
        ON c.customerID = o.customerID
    JOIN orderdetails od
        ON o.orderID = od.orderID
    JOIN products p
        ON od.productID = p.productID
    WHERE p.productName = 'Chai'
)
GROUP BY c.customerID, c.companyName
HAVING COUNT(DISTINCT o.orderID) > 20
ORDER BY no_of_orders DESC;

-- 17.Show the ranking of products bASed on total units sold across all orders. 

SELECT * FROM products;
SELECT * FROM orderdetails;

SELECT p.productID,p.productName , SUM(od.quantity) AS qyt ,
	dense_rank()OVER(
		ORDER BY  SUM(od.quantity) DESC	
    ) AS product_rank
FROM products AS p
JOIN orderdetails AS od
on p.productID = od.productID
GROUP BY p.productID ,p.productName;

-- 18.Find the second highest selling product in each category. 

SELECT * FROM products;

SELECT * FROM
(SELECT p.productID,p.productName,c.categoryName, SUM(od.quantity) AS qyt ,
	dense_rank()OVER(
		partition by c.categoryName
		ORDER BY  SUM(od.quantity) DESC	
    ) AS product_rank
FROM products AS p
JOIN orderdetails AS od
on p.productID = od.productID
JOIN categories AS c
on p.categoryID = c.categoryID
GROUP BY p.productID ,p.productName,c.categoryName) AS t
WHERE product_rank = 2;

-- 19.Show employees and their manager's name (use self JOIN). 

SELECT e.employeeID, e.firstName,e.lAStName,e.title,
    m.firstName AS manager_firstname,
    m.lAStName AS manager_lAStname
FROM employees e
LEFT JOIN employees m
ON e.reportsTo = m.employeeID;	

-- 20.Display the running total of freight cost per customer ordered by order date. 

SELECT c.companyName,o.orderID,o.orderDate,o.freight,
    SUM(o.freight) OVER (
        PARTITION BY c.customerID ORDER BY o.orderDate
    ) AS running_freight
FROM customers c
JOIN orders o
    ON c.customerID = o.customerID
ORDER BY c.companyName,o.orderDate;


-- 21.Find orders that were placed on the lASt day of any month. 

SELECT orderID,customerID,orderDate
FROM orders
WHERE orderDate = LAST_DAY(orderDate);

-- 22.Show the percentage contribution of each shipper in total freight charges. 

WITH shipper_total_freight AS(
	SELECT s.companyName , round(sum(o.freight),2) AS total_freight
    FROM shippers AS s
    JOIN orders o
    on s.shipperID = o.shipVia
    GROUP BY s.companyName
)
SELECT companyName , total_freight , ROUND(total_freight * 100.0 / SUM(total_freight) OVER (),2) AS pct
FROM shipper_total_freight;

-- 23.Find products whose price is higher than the average price of all products in their category.

SELECT p.productName , c.categoryName , sum(p.unitPrice) AS total_price
FROM products AS p
JOIN categories AS c
on p.categoryID = c.categoryID
GROUP BY p.productName,c.categoryName
HAVING total_price > (SELECT avg(unitPrice) FROM products)
ORDER BY total_price DESC;
 
-- 24.Display the number of orders placed on weekends vs weekdays. 

SELECT 
	CASE
		When dayofweek(orderDate) IN  (1,7) then "Weekends"
        else "Weekdays"
	END AS daystype,
    count(*) AS no_of_orders
FROM orders
GROUP BY daystype;

-- 25.Show customers who have the same city AS their ship address in at leASt 3 orders. 



SELECT c.companyName,c.city,count(*) AS no_of_orders
    FROM customers AS c
    JOIN orders AS o
    on c.customerID = o.customerID
    WHERE c.city = o.shipCity
    GROUP BY c.companyName,c.city
    HAVING  no_of_orders > 3
    ORDER BY c.city;

-- 26.Find the month with the highest average order value in 1997.
SELECT
    MONTH(o.orderDate) AS month_no,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM (
    SELECT o.orderID,o.orderDate,
        SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS order_value
    FROM orders o
    JOIN orderdetails od
        ON o.orderID = od.orderID
    WHERE YEAR(o.orderDate) = 1997
    GROUP BY o.orderID, o.orderDate
) AS o
GROUP BY MONTH(o.orderDate)
ORDER BY avg_order_value DESC
LIMIT 1;
 
-- 27.Show the top 3 employees by revenue generated through their orders. 

SELECT e.firstName , sum(od.quantity * od.unitPrice) AS revenue
FROM employees AS e
JOIN orders AS o
on e.employeeID = o.employeeID
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY e.firstName
ORDER BY revenue DESC LIMIT 3;

-- 28.Find all products that were supplied by suppliers FROM the same country AS the customer. 

SELECT p.productName,s.companyName ,c.country,s.country
FROM suppliers AS s
JOIN products AS p
on s.supplierID = p.supplierID
JOIN orderdetails AS od
on p.productID = od.productID
JOIN orders AS o
on od.orderID = o.orderID
JOIN customers AS c
on o.customerID = c.customerID
WHERE c.country = s.country;


-- 29.Display the growth percentage in sales month-over-month for the year 1997. 

WITH monthly_sales AS (
	SELECT MONTH(o.orderDate) AS month_no,   
		ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS total_sales
    FROM orders AS o
    JOIN orderdetails AS od
    on o.orderID = od.orderID
    WHERE YEAR(o.orderDate) = 1997
    GROUP BY MONTH(o.orderDate)
)
SELECT month_no,total_sales,
	LAG(total_sales)OVER(
		ORDER BY month_no
    ) AS previous_sales,
    ROUND(
		(total_sales - LAG(total_sales)OVER(ORDER BY month_no)) * 100 
        / LAG(total_sales)OVER(ORDER BY month_no),
        2
    ) AS growth_pct
FROM monthly_sales
ORDER BY month_no;

-- 30.Show orders WHERE the freight cost is more than 10% of the total order value. 

SELECT o.orderID , o.freight , ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount))*.1, 2) AS order_value_10
FROM orders AS o
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY o.orderID , o.freight
HAVING o.freight > order_value_10;

-- 31. Find the customer with the highest number of unique products purchASed.

SELECT c.customerID,c.companyName , count(distinct(od.productID)) AS pro_count
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY c.customerID,c.companyName
ORDER BY pro_count DESC LIMIT 1;

-- 32. Show the list of employees who report to the same manager.

SELECT e.employeeID, e.firstName,e.lAStName,e.title,
    m.firstName AS manager_firstname,
    m.lAStName AS manager_lAStname
FROM employees e
LEFT JOIN employees m
ON e.reportsTo = m.reportsTo     AND e.EmployeeID < m.EmployeeID;
-- WHERE e.reportsTo is null;	

-- 33. Find categories WHERE the average unit price is higher than the overall average.

SELECT c.categoryID,c.categoryName , round(avg(p.unitPrice),2) AS avg_unitPrice
FROM categories AS c
JOIN products AS p 
on c.categoryID = p.categoryID
GROUP BY c.categoryID,c.categoryName
HAVING avg_unitPrice > (SELECT avg(unitPrice) FROM products)
ORDER BY avg_unitPrice DESC;

-- 34. Display the cumulative profit (ASsuming 30% margin) per customer.

SELECT c.customerID,c.companyName , 
	SUM((od.quantity * od.unitPrice * (1-od.discount)))OVER(
		partition by customerID
        ORDER BY c.customerID
    ) AS cumulative_profit
FROM customers  AS c
JOIN orders  AS o
on  c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID;
    

-- 35. Show products that have been ordered by more than 40 different customers.

SELECT p.productID,p.productName , count(distinct o.customerID) AS user_count
FROM products  AS p
JOIN orderdetails AS od
on p.productID = od.productID
JOIN orders AS o
on od.orderID = o.orderID	
GROUP BY p.productID,p.productName
HAVING user_count > 40
ORDER BY user_count DESC;

-- 36. Find the most frequently ordered product in each region (bASed on ship country).
SELECT o.shipCountry, p.productID, p.productName, COUNT(*) AS order_count
FROM orders AS o
JOIN orderdetails od
ON o.orderID = od.orderID
JOIN products p
ON od.productID = p.productID
GROUP BY o.shipCountry, p.productID, p.productName
ORDER BY order_count DESC;


-- 37. Show the rank of each order bASed on freight cost within its ship country.

SELECT orderID,freight,shipCountry,
	RANK()over(
		partition by shipCountry
        ORDER BY freight DESC
    ) AS Rank_Freight
FROM orders;

-- 38. Find customers who placed orders in January but not in December of the same year.

SELECT
    customerID,
    YEAR(orderDate) AS order_year
FROM orders
GROUP BY customerID, YEAR(orderDate)
HAVING SUM(MONTH(orderDate) = 1) > 0
AND SUM(MONTH(orderDate) = 12) = 0;
   
-- 39. Display the total discount given per category.

SELECT c.categoryID , c.categoryName , SUM(od.unitPrice * od.quantity * od.discount) AS total_discount
FROM categories AS c
JOIN products AS p
on c.categoryID = p.categoryID
JOIN orderdetails AS od
on p.productID  = od.productID
GROUP BY c.categoryID , c.categoryName
ORDER BY total_discount DESC;

SELECT * FROM orderdetails;

-- 40. Show the top 5 cities with the highest number of orders but the lowest average freight.

SELECT shipCity , count(orderID) AS no_of_orders , avg(freight) AS avg_freight
FROM orders
GROUP BY shipCity
ORDER BY no_of_orders DESC , avg_freight
LIMIT 5;

-- 41. Find orders that were delayed by more than 10 days.

SELECT orderID , requiredDate , shippedDate , DATEDIFF(shippedDate,requiredDate) AS  delaydays
FROM orders
WHERE DATEDIFF(shippedDate,requiredDate) > 10;

-- 42. Show the percentage of orders shipped by each shipper per year.

with orderForshipper AS (
	SELECT YEAR(o.orderDate) AS order_year , s.companyName , count(*) AS total_orders
    FROM orders AS o
    JOIN shippers AS s
    on o.shipVia = s.shipperID
    GROUP BY YEAR(o.orderDate) , s.companyName
)

SELECT order_year , companyName	 , total_orders , 
	ROUND((total_orders  / SUM(total_orders) OVER(PARTITION BY order_year))*100,2) AS pct
    FROM orderForshipper
    ORDER BY order_year , pct DESC ; 

-- 43. Find employees who have not handled any order in 1998.

with order_in_1998 AS (
	SELECT distinct employeeID
    FROM orders
    WHERE year(orderDate) = 1998
)

SELECT e.employeeID,concat(e.firstName," ",e.lAStName) AS fullname
FROM employees AS e
LEFT JOIN order_in_1998 AS o
on e.employeeID = o.employeeID
WHERE e.employeeID is null;

-- 44. Display products that were reordered (UnitsOnOrder > 0) but are discontinued.

SELECT productName , unitPrice , unitsOnOrder , discontinued
FROM products 
WHERE unitsOnOrder > 0 and discontinued =  1;

-- 45. Show the average time gap between consecutive orders for each customer.

SELECT * FROM customers;
SELECT * FROM orders;

SELECT c.customerID , c.companyName , 
	LAG(1)OVER(
		partition by c.customerID
        ORDER BY o.orderDate
    );

-- 46. Find the product with the highest variance in unit price across different orders.

SELECT
    p.productName,
    VARIANCE(od.unitPrice) AS price_variance
FROM products p
JOIN order_details od
    ON p.productID = od.productID
GROUP BY p.productName
ORDER BY price_variance DESC
LIMIT 1;

SELECT
    p.productName,
    STD(od.unitPrice) AS price_stddev
FROM products p
JOIN orderdetails od
    ON p.productID = od.productID
GROUP BY p.productName
ORDER BY price_stddev DESC
LIMIT 1;

-- 47. Show a list of customers who only buy FROM one category.

SELECT c.customerID , c.companyName,count(distinct(p.categoryID)) AS category_count
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
JOIN products AS p
on od.productID  = p.productID
GROUP BY c.customerID , c.companyName
HAVING category_count = 1;
   

-- 48. Display the top 10 orders with the highest (Freight ÷ Order Value) ratio.

SELECT o.orderID ,ROUND((o.freight / sum(od.unitPrice*od.quantity *(1-discount))),4) AS ratio
FROM orders AS o
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY orderID , o.freight
ORDER BY ratio DESC LIMIT 10;

-- 49. Find how many customers have placed orders worth more than $10,000 in total.

SELECT count(*) AS No_of_Customers
FROM 
	(
		SELECT c.customerID , c.companyName , sum(od.unitPrice*od.quantity *(1-discount)) AS total_value
		FROM customers AS c
		JOIN orders AS o
		on c.customerID = o.customerID
		JOIN orderdetails AS od
		on o.orderID = od.orderID
		GROUP BY c.customerID , c.companyName
		HAVING total_value > 10000
		ORDER BY total_value DESC
	) 
AS t;


-- 50. Show the distribution of order values in 4 buckets (e.g., 0–500, 501–2000, 2001–5000, Above 5000)

SELECT o.orderID , sum(od.quantity *unitPrice * (1-discount)) AS order_value ,
	CASE
		WHEN sum(od.quantity *unitPrice * (1-discount)) between 0 and 500 then "0-500"
		WHEN sum(od.quantity *unitPrice * (1-discount)) between 501 and 2000 then "501 - 2000"
        WHEN sum(od.quantity *unitPrice * (1-discount)) between 2001 and 5000 then "2001 - 5000"
        ELSE "Above 5000"
        END AS bucket_values
FROM orders AS o
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY orderID;


-- 51.Find suppliers who supply more than 5 products that are currently in stock. 

SELECT s.supplierID,s.companyName , count(distinct(p.productID)) AS no_of_product
FROM suppliers AS s
JOIN products AS p
on s.supplierID = p.supplierID
WHERE p.unitsInStock > 0
GROUP BY s.supplierID , s.companyName
HAVING no_of_product > 5;

SELECT * FROM products;

-- 52.Show the month-wise comparison of total sales between 1996 and 1997.

SELECT 
    YEAR(o.orderDate) AS order_year,
    MONTH(o.orderDate) AS order_month,
    SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS total_sales
FROM orders o
JOIN orderdetails od
    ON o.orderID = od.orderID
WHERE YEAR(o.orderDate) IN (1996, 1997)
GROUP BY YEAR(o.orderDate), MONTH(o.orderDate)
ORDER BY order_month, order_year;

-- 53.Display customers who have increASed their spending FROM 1996 to 1997. 

SELECT c.customerID , c.companyName , 
    SUM(CASE
		WHEN YEAR(o.orderDate) = 1996 
			THEN od.unitPrice * od.quantity * (1 - od.discount) 
		ELSE 0
	END) AS sales_1996,
    SUM(CASE
		WHEN YEAR(o.orderDate) = 1997
			THEN od.unitPrice * od.quantity * (1 - od.discount) 
		ELSE 0
	END) AS sales_1997
FROM customers AS c 
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY c.customerID , c.companyName
HAVING sales_1997 > sales_1996;
    
-- 54.Find the leASt profitable category after deducting 15% handling cost. 

SELECT c.categoryID , c.categoryName , ROUND(SUM(od.unitPrice * od.quantity * (1-od.discount) *.85),2) AS profit
FROM categories AS c
JOIN products AS p
on c.categoryID = p.categoryID
JOIN orderdetails AS od
on p.productID = od.productID
GROUP BY c.categoryID , c.categoryName
ORDER BY profit LIMIT 1;

-- 55.Show the running total of quantity sold for each product. 

SELECT p.productID , p.productName , od.quantity,
	SUM(od.quantity)OVER(
		partition by p.productID
        ORDER BY od.orderID
    ) AS running_total
FROM products AS p
JOIN orderdetails AS od
on p.productID = od.productID
ORDER BY p.productID , p.productName;

-- 56.Find orders WHERE multiple products FROM the same category were purchASed. 

SELECT od.orderID ,c.categoryID, c.categoryName , count(distinct(p.productID)) AS product_count
FROM categories AS c
JOIN products AS p 
on c.categoryID = p.categoryID
JOIN orderdetails AS od
on p.productID = od.productID
GROUP BY od.orderID ,c.categoryID, c.categoryName
HAVING product_count > 1
ORDER BY product_count DESC;


-- 57.Display the top 5 products with highest profit margin per unit. 

SELECT p.productID , p.productName , ROUND(AVG(od.unitPrice * 0.3),2) AS profit
FROM products AS p
JOIN orderdetails AS od
on p.productID = od.productID
GROUP BY p.productID , p.productName
ORDER BY profit DESC LIMIT 5;

SELECT
    p.productName,
    ROUND(
        AVG(
            ((od.unitPrice - p.unitPrice)
            / od.unitPrice) * 100
        ), 2
    ) AS profit_margin
FROM products p
JOIN orderdetails od
    ON p.productID = od.productID
GROUP BY p.productID, p.productName
ORDER BY profit_margin DESC
LIMIT 5;

-- 58.Show employees who handled orders FROM more than 10 different countries.

SELECT e.employeeID,concat(e.firstName," ",e.lAStName) AS fullname , count(distinct(o.shipCountry)) AS no_of_country
FROM employees AS e
JOIN orders AS o
on e.employeeID = o.employeeID
GROUP BY e.employeeID , fullname
HAVING no_of_country > 10
ORDER BY no_of_country DESC;

-- 59.Find the correlation trend between discount and quantity ordered. 

SELECT ((COUNT(*) * SUM(quantity * discount)) - (SUM(quantity)*SUM(discount)))
        /
        Sqrt(
            (count(*) * SUM(quantity * quantity) - Power(sum(quantity),2))
            *
            (count(*) * SUM(discount * discount) - Power(sum(discount),2))

        )
        AS correlation
FROM orderdetails;


SELECT
    COVAR_POP(quantity, discount)
    /
    (
        STDDEV_POP(quantity)
        *
        STDDEV_POP(discount)
    ) AS correlation
FROM orderdetails;


SELECT * FROM orderdetails;


-- 60.Show customers who have never ordered FROM 'Beverages' category. 

SELECT c.customerID , c.companyName
FROM customers AS c
WHERE not exists (
    SELECT 1
    FROM orders AS o
    JOIN orderdetails AS od
    on o.orderID = od.orderID
    JOIN products AS p
    on od.productID = p.productID
    JOIN categories AS ca
    on p.categoryID = ca.categoryID
    WHERE o.customerID = c.customerID and ca.categoryName = "Beverages"
);

-- 61.Display the 3rd highest order value for each customer.


SELECT * FROM 
(
	SELECT o.orderID,c.customerID , c.companyName , SUM(od.quantity *  od.unitPrice * (1-od.discount)) AS total_value,
		dense_rank()OVER(
			partition by c.customerID
			ORDER BY SUM(od.quantity *  od.unitPrice * (1-od.discount)) DESC
		) AS cust_rank
    FROM customers AS c
    JOIN orders AS o
    on c.customerID = o.customerID
    JOIN orderdetails AS od
    on o.orderID =  od.orderID
    GROUP BY o.orderID,c.customerID , c.companyName
)  AS t
WHERE cust_rank = 3
ORDER BY  total_value DESC;

-- Using CTE

WITH ranks AS (
    SELECT o.orderID,c.customerID , c.companyName , SUM(od.quantity *  od.unitPrice * (1-od.discount)) AS total_value,
		dense_rank()OVER(
			partition by c.customerID
			ORDER BY SUM(od.quantity *  od.unitPrice * (1-od.discount)) DESC
		) AS cust_rank
    FROM customers AS c
    JOIN orders AS o
    on c.customerID = o.customerID
    JOIN orderdetails AS od
    on o.orderID =  od.orderID
    GROUP BY o.orderID,c.customerID , c.companyName
)
SELECT * FROM ranks
WHERE cust_rank = 3
ORDER BY total_value DESC;
    
-- 62.Find the average number of days between order placement and shipping per shipper. 

SELECT s.shipperID , s.companyName , round(avg(DATEDIFF(o.orderDate,o.shippedDate)),2) AS avg_days
FROM orders AS o
JOIN shippers AS s
on o.shipVia = s.shipperID
GROUP BY s.shipperID , s.companyName
ORDER BY avg_days DESC;

-- 63.Show products that were ordered in every quarter of 1997. 

SELECT p.productID , p.productName , count(distinct(quarter(o.orderDate))) AS quarter_no
FROM products AS p
JOIN orderdetails AS od
on p.productID = od.productID
JOIN orders AS o
on od.orderID = o.orderID
GROUP BY p.productID , p.productName
HAVING quarter_no = 4;

-- 64.Find the customer with the most consistent order value (lowest variance). 

WITH order_value AS (
	SELECT o.orderID,c.customerID , c.companyName , SUM(od.quantity * od.unitPrice * (1-od.discount)) ordervalue
    FROM customers AS c
    JOIN orders AS o
    on c.customerID = o.customerID
    JOIN orderdetails AS od
    on o.orderID = od.orderID
    GROUP BY o.orderID,c.customerID , c.companyName
)
SELECT customerID , companyName , variance(ordervalue) AS var_order
FROM order_value
GROUP BY customerID,companyName
ORDER BY var_order LIMIT 5;

-- 65.Display year-wise total orders handled by each employee. 

SELECT YEAR(o.orderDate) AS year,e.employeeID , concat(e.firstName , " ",e.lAStName) AS fullname  , count(o.orderID) AS no_of_orders
FROM employees AS e
JOIN orders AS o
on e.employeeID = o.employeeID
GROUP BY YEAR(o.orderDate),e.employeeID , concat(e.firstName , " ",e.lAStName)
ORDER BY no_of_orders DESC;

-- 66.Show the percentage of loss-making orders (negative profit not applicable here, but delayed orders).

SELECT ROUND(
                COUNT(CASE WHEN shippedDate > requiredDate THEN 1 END) * 100 / count(*),
                2
            ) AS order_delayed_pct
FROM orders;

SELECT 
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN shippedDate > requiredDate THEN 1 END) AS delayed_orders,
    ROUND(
        COUNT(CASE WHEN shippedDate > requiredDate THEN 1 END) * 100.0
        / COUNT(*),
        2
    ) AS delayed_order_percentage
FROM orders;


-- 67.Find the most popular product combination (ordered together) using self JOIN on order_details. 

SELECT p.productName AS product_1 , p2.productName AS product_2 , count(*) AS no_of_time
FROM orderdetails AS od1
JOIN orderdetails AS od2
on od1.orderID = od2.orderID 
    and od1.productID < od2.productID
JOIN products AS p
on od1.productID = p.productID
JOIN products AS p2
on od2.productID = p2.productID
GROUP BY p.productName, p2.productName
ORDER BY no_of_time DESC
LIMIT 10;

-- 68.Show the top 10 longest gaps between two consecutive orders for any customer. 

WITH gap_date AS(
    SELECT c.customerID ,c.companyName ,o.orderDate,
    LAG(o.orderDate)OVER(
        partition by c.customerID
        ORDER BY o.orderDate
    )AS previous_date
    FROM customers AS c
    JOIN orders AS o
    on c.customerID = o.customerID
)

SELECT customerID , companyName , orderDate , previous_date , 
        DATEDIFF(orderDate,previous_date) AS gap_days
FROM gap_date
ORDER BY gap_days DESC
LIMIT 10;

-- 69.Display categories with more than 10 products that have zero units on order. 

SELECT c.categoryID , c.categoryName , count(*) AS no_of_product
FROM categories AS c
JOIN products AS p
on c.categoryID = p.categoryID
WHERE p.unitsOnOrder = 0
GROUP BY c.categoryID , c.categoryName
HAVING no_of_product > 10;

-- 70.Find how many orders were shipped late by more than 7 days in each region. 

SELECT c.region,count(o.orderID) AS no_of_orders
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
WHERE DATEDIFF(o.shippedDate,o.requiredDate) > 7
GROUP BY c.region
ORDER BY no_of_orders DESC;


-- 71.Show the contribution of each employee to total company revenue. 

SELECT e.employeeID , concat(e.firstName," ",e.lAStName) AS fullname , ROUND(SUM(od.quantity * od.unitPrice *  (1- od.discount)),2) AS total_sales
FROM employees AS e
JOIN orders AS o
on e.employeeID = o.employeeID
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY e.employeeID , concat(e.firstName," ",e.lAStName)
ORDER BY total_sales DESC;

-- 72.Find products whose name starts with a vowel and have been ordered more than 30 times. 

With orderwithvowel AS (
    SELECT productID , productName 
    FROM products
    WHERE productName like "A%" or productName like "a%"
       OR productName like "E%" or productName like "e%"
       OR productName like "I%" or productName like "i%"
       OR productName like "O%" or productName like "o%"
       OR productName like "U%" or productName like "u%"
)

SELECT ow.productID , ow.productName , count(*) AS total_orders
FROM orderwithvowel AS ow
JOIN orderdetails AS od
on ow.productID = od.productID
GROUP BY ow.productID , ow.productName
HAVING total_orders > 30;

-- 73.Display the rank of shippers bASed on on-time delivery percentage. 


WITH delivery_stats AS (
    SELECT s.shipperID,s.companyName,COUNT(*) AS total_orders,
    SUM(
        CASE
                WHEN o.shippedDate <= o.requiredDate THEN 1
                ELSE 0
            END
        ) AS on_time_orders
    FROM shippers AS s
    JOIN orders AS o
        ON s.shipperID = o.shipVia
    GROUP BY s.shipperID, s.companyName
)
SELECT
    shipperID,
    companyName,
    ROUND((on_time_orders * 100.0) / total_orders, 2) AS on_time_percentage,
    RANK() OVER (
        ORDER BY (on_time_orders * 100.0) / total_orders DESC
    ) AS shipper_rank
FROM delivery_stats;

-- 74.Show customers who placed orders on the same day they were born (month and day). 
    -- Here we Don't have any bith date column so we can't find it

-- 75.Find the total revenue generated by each territory (if territories loaded). 
    -- We can't have any territory table info so we can derived.

-- 76.Show the difference in average order value between weekdays and weekends. 

With avg_order_values AS (
    SELECT o.orderID , 
        SUM(
            CASE 
                When  dayofweek(o.orderDate) IN  (1,7) then 
                (od.quantity * od.unitPrice * (1-od.discount))
            else NULL
            END
        ) AS weekend_order_value,
        SUM(
            CASE 
                 When dayofweek(o.orderDate) NOT IN  (1,7) then 
                (od.quantity * od.unitPrice * (1-od.discount))
            else NULL
            END
        ) AS weekday_order_value
    FROM orders AS o
    JOIN orderdetails  AS od
    on o.orderID = od.orderID
    GROUP BY o.orderID
)
SELECT
    AVG(weekend_order_value) AS weekend_avg_order_value,
    AVG(weekday_order_value) AS weekday_avg_order_value,
    AVG(weekday_order_value) - AVG(weekend_order_value) AS difference
FROM avg_order_values;

-- 77.Find the top 5 products that contribute to more than 50% of a category’s revenue. 

With product_revenue AS (
	SELECT c.categoryID,c.categoryName,p.productID,p.productName,SUM(od.quantity * od.unitPrice * (1-od.discount)) AS pro_revenue
    FROM categories AS c
    JOIN products AS p
    on c.categoryID = p.categoryID
    JOIN orderdetails AS od
    on p.productID = od.productID
    GROUP BY p.productID,p.productName,c.categoryID,c.categoryName
),
category_revenue AS (
    SELECT categoryID,SUM(pro_revenue) AS category_revenue
    FROM product_revenue
    GROUP BY categoryID
)
SELECT pr.categoryName,pr.productID,pr.productName,pr.pro_revenue,cr.category_revenue,
       ROUND(((pr.pro_revenue / cr.category_revenue) * 100),2) AS revenue_ptc
FROM product_revenue AS pr
JOIN category_revenue AS cr
on pr.categoryID = cr.categoryID
WHERE pr.pro_revenue > .5 * cr.category_revenue
ORDER BY pr.pro_revenue DESC
LIMIT 5;


-- 78.Display orders WHERE the customer and shipper are FROM the same country. 

SELECT o.orderID , c.country AS  cust_country , o.shipCountry 
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
WHERE c.country = o.shipCountry;

-- 79.Show the growth rate of new customers acquired each year. 

-- 80.Find products that have the highest number of returns (ASsuming high discount = return proxy). 

SELECT p.productID , p.productName , Count(*) AS no_of_return
FROM products AS p
JOIN orderdetails AS od
on p.productID = od.productID
WHERE od.discount > 0.2
GROUP BY p.productID , p.productName;


-- 81.Display a summary of average, min, and max order value per segment. 

SELECT c.categoryID , c.categoryName , ROUND(AVG(od.quantity * od.unitPrice*(1- od.discount)),2) AS avg_order,
        ROUND(MIN(od.quantity * od.unitPrice*(1- od.discount)),2) AS min_value,
        ROUND(MAX(od.quantity * od.unitPrice*(1- od.discount)),2) AS max_value
FROM categories AS c
JOIN products AS p
on c.categoryID = p.categoryID
JOIN orderdetails AS od
on p.productID = od.productID
GROUP BY c.categoryID , c.categoryName;


-- 82.Show employees who JOINed before 1993 and have handled more than 100 orders. 

SELECT e.employeeID , concat(e.firstName," ",e.lAStName) AS fullname , count(*) AS no_of_orders
FROM employees AS e
JOIN orders AS o
on e.employeeID = o.employeeID
WHERE YEAR(e.hireDate) < 1993
GROUP BY e.employeeID,concat(e.firstName," ",e.lAStName)
HAVING no_of_orders > 100;


-- 83.Find the most delayed order (in days) and the customer ASsociated with it. 

SELECT c.customerID , c.companyName , o.orderID , DATEDIFF(o.shippedDate ,o.requiredDate) AS no_days
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
ORDER BY no_days DESC LIMIT 1;

-- 84.Show percentage of orders that were shipped within 3 days. 

WITH orderwith3 AS (
    SELECT o.orderID
    FROM orders AS o
    WHERE DATEDIFF(o.shippedDate,o.orderDate) <= 3
)

SELECT ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM orders),2) AS percentage_orders_within_3_days
FROM orderwith3;


SELECT ROUND(
       SUM(
           CASE
               WHEN DATEDIFF(shippedDate,orderDate) <= 3 THEN 1
               ELSE 0
           END
       ) * 100.0 / COUNT(*),
       2
       ) AS percentage_orders_within_3_days
FROM orders;


-- 85.Display the top 10 customers with highest lifetime value. 

SELECT c.customerID , c.companyName  ,SUM(od.quantity * od.unitPrice * (1-od.discount)) AS total_value
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY c.customerID , c.companyName
ORDER BY total_value DESC LIMIT 10;


-- 86.Find categories WHERE average discount is higher than overall average discount. 

SELECT c.categoryID , c.categoryName , AVG(od.discount) AS cat_avg
FROM categories AS c
JOIN products AS p
on c.categoryID = p.categoryID
JOIN orderdetails AS od
on p.productID = od.productID
GROUP BY c.categoryID , c.categoryName 
HAVING cat_avg > (SELECT avg(discount) FROM orderdetails);

-- 87.Show how many unique suppliers are used per category. 

SELECT c.categoryID,c.categoryName,COUNT(DISTINCT p.supplierID) AS no_of_suppliers
FROM categories AS c
JOIN products AS p
on c.categoryID = p.categoryID
GROUP BY c.categoryID,c.categoryName;

-- 88.Find the customer who hAS the highest ratio of distinct products to total orders. 

SELECT c.customerID , c.companyName , COUNT(distinct(od.productID)) AS no_of_product,
        count(o.orderID) AS total_orders,
        ROUND(COUNT(DISTINCT od.productID) / COUNT(DISTINCT o.orderID),2) AS ratio

FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY c.customerID , c.companyName
ORDER BY ratio DESC LIMIT 1;


-- 89.Display the trend of average freight cost over the years. 

SELECT YEAR(orderDate) AS year , ROUND(avg(freight),2) AS avg
FROM orders 
GROUP BY year
ORDER BY year;

-- 90.Show products that were never discontinued but have very low stock. 

SELECT productID , productName 
FROM products 
WHERE discontinued = 0 and unitsInStock < 2;


-- 91.Find the busiest shipping day of the week. 

SELECT DayName(shippedDate) AS shipping_day , count(*) AS total_shipment
FROM orders 
GROUP BY shipping_day
ORDER BY total_shipment DESC LIMIT 1;

-- 92.Display the top 5 most valuable (high monetary) inactive customers (no order in 1998). 

SELECT c.customerID , c.companyName , SUM(od.quantity * od.unitPrice * (1-od.discount)) AS total_value
FROM customers AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN orderdetails AS od
on o.orderID = od.orderID
WHERE c.customerID not in (
        SELECT customerID FROM orders
        WHERE YEAR(orderDate) = 1998
    )
GROUP BY c.customerID , c.companyName
ORDER BY  total_value DESC LIMIT 5;

-- 93.Show the impact of employee on order freight cost (average per employee). 

SELECT e.employeeID , concat(e.firstName," ",e.lAStName) AS fullname , ROUND(AVG(o.freight),2) AS avg_freight
FROM employees AS e
JOIN orders AS o
on e.employeeID = o.employeeID
GROUP BY e.employeeID , fullname
ORDER BY avg_freight DESC;

-- 94.Find duplicate company names in customers and suppliers combined. 

SELECT c.companyName , s.companyName , count(*) AS no_count
FROM customers  AS c
JOIN orders AS o
on c.customerID = o.customerID
JOIN shippers AS s
on o.shipvia = s.shipperID
GROUP BY c.companyName , s.companyName
HAVING no_count > 1;

SELECT companyName, COUNT(*) AS no_count
FROM (
    SELECT companyName
    FROM customers
    
    UNION ALL
    
    SELECT companyName
    FROM suppliers
) AS combined
GROUP BY companyName
HAVING COUNT(*) > 1;

-- 95.Display the total sales value handled by each employee per quarter. 
SELECT e.employeeID , concat(e.firstName," ",e.lAStName) AS fullname , quarter(o.orderDate) AS per_quarter,
        ROUND(SUM(od.quantity * od.unitPrice * (1-od.discount)),2) AS total_value
FROM employees AS e
JOIN orders AS o
on e.employeeID = o.employeeID
JOIN orderdetails AS od
on o.orderID = od.orderID
GROUP BY e.employeeID  , fullname , per_quarter
ORDER BY total_value DESC;
 
-- 96.Show the percentage of international orders (ship country != customer country). 

SELECT ROUND(
        SUM(
                CASE
                    WHEN o.shipCountry <> c.country THEN 1
                    ELSE 0
                END
            ) * 100.0 / COUNT(*),
        2
    ) AS international_order_percentage
FROM orders o
JOIN customers c
ON o.customerID = c.customerID;

-- 97.Find the product with the longest time between first and lASt order. 

WITH product_duration AS (
    SELECT p.productID,p.productName,DATEDIFF(MAX(o.orderDate),MIN(o.orderDate)) AS days_between
    FROM products p
    JOIN orderdetails od
    ON p.productID = od.productID
    JOIN orders o
    ON od.orderID = o.orderID
    GROUP BY p.productID, p.productName
)
SELECT *
FROM product_duration
ORDER BY days_between DESC
LIMIT 1;

-- 98.Display customers who ordered all products FROM a particular category.

SELECT o.customerID,p.categoryID
FROM orders o
JOIN orderdetails od
ON o.orderID = od.orderID
JOIN products p
ON od.productID = p.productID
GROUP BY o.customerID, p.categoryID
HAVING COUNT(DISTINCT p.productID) =
(
    SELECT COUNT(*)
    FROM products p2
    WHERE p2.categoryID = p.categoryID
);
 
-- 99.Show the efficiency of each shipper (average shipping days). 

SELECT s.shipperID,s.companyName,ROUND(AVG(DATEDIFF(o.shippedDate, o.orderDate)),2) AS avg_shipping_days
FROM shippers s
JOIN orders o
ON s.shipperID = o.shipVia
WHERE o.shippedDate IS NOT NULL
GROUP BY s.shipperID, s.companyName;

-- 100.Create a final ranking of all customers bASed on a weighted score of Recency, Frequency, and Monetary value. 

WITH rfm AS (
    SELECT c.customerID,
           DATEDIFF('1998-05-31', MAX(o.orderDate)) AS recency,
           COUNT(DISTINCT o.orderID) AS frequency,
           ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS monetary
    FROM customers AS c
    JOIN orders AS o
    ON c.customerID = o.customerID
    JOIN orderdetails AS od
    ON o.orderID = od.orderID
    GROUP BY c.customerID
),
rfm_score AS (
    SELECT customerID, recency, frequency, monetary,
           NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency) AS f_score,
           NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm
)
SELECT customerID, recency, frequency, monetary, r_score, f_score, m_score,
       ROUND(r_score * 0.3 + f_score * 0.3 + m_score * 0.4, 2) AS weighted_score,
       RANK() OVER (ORDER BY r_score * 0.3 + f_score * 0.3 + m_score * 0.4 DESC) AS customer_rank
FROM rfm_score
ORDER BY customer_rank;