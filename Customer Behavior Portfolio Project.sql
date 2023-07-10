CREATE DATABASE DinerProject;

USE DinerProject;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

--1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, SUM(menu.price) AS total_spent
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visited
FROM sales
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?

WITH first_purchase AS (
	SELECT customer_id, MIN(order_date) AS first_purchase_date
	FROM sales
	GROUP BY customer_id
	)
SELECT fp.customer_id, menu.product_name
FROM first_purchase fp
JOIN sales
ON fp.customer_id = sales.customer_id AND fp.first_purchase_date = sales.order_date
JOIN menu
ON sales.product_id = menu.product_id


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 menu.product_name, count(*) AS total_item
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_item DESC

-- 5. Which item was the most popular for each customer?

WITH product_rank AS (
	SELECT sales.customer_id, menu.product_name, count(*) AS total_item, ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(*) DESC) AS ranking
	FROM sales
	JOIN menu
	ON sales.product_id = menu.product_id
	GROUP BY sales.customer_id, menu.product_name
)

SELECT customer_id, product_name, total_item
FROM product_rank
WHERE ranking = 1

-- 6. Which item was purchased first by the customer after they became a member?

WITH order_rank AS (
	SELECT members.customer_id, sales.product_id, sales.order_date, ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS ranking
	FROM sales
	JOIN members
	ON sales.customer_id = members.customer_id
	WHERE sales.order_date >= members.join_date
)

SELECT order_rank.customer_id,  menu.product_name
FROM order_rank
JOIN menu
ON menu.product_id = order_rank.product_id
WHERE ranking = 1


-- 7. Which item was purchased just before the customer became a member?

WITH last_order_before_membership AS (
	SELECT members.customer_id, MAX(sales.order_date) as latest_order_date
	FROM sales
	JOIN members
	ON sales.customer_id = members.customer_id
	WHERE sales.order_date < members.join_date
	GROUP BY members.customer_id
)

SELECT last_order_before_membership.customer_id, menu.product_name
FROM last_order_before_membership
JOIN sales
ON last_order_before_membership.customer_id = sales.customer_id
	AND last_order_before_membership.latest_order_date = sales.order_date
JOIN menu
ON menu.product_id = sales.product_id
ORDER BY customer_id

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT members.customer_id, COUNT(*) AS total_items, SUM(price) AS total_spent
FROM sales
JOIN members
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
GROUP BY members.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT sales.customer_id, 
SUM(CASE WHEN product_name = 'sushi' THEN menu.price*20 ELSE menu.price*10 END) AS total_points
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT sales.customer_id, 
--SUM(CASE WHEN product_name = 'sushi' THEN menu.price*20 ELSE menu.price*10 END) AS total_points
SUM(CASE WHEN (sales.order_date >= members.join_date AND sales.order_date <=  DATEADD(day,7,members.join_date)) THEN menu.price*20
	WHEN product_name = 'sushi' THEN menu.price*20
	ELSE menu.price*10 END) AS total_points
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id
WHERE sales.order_date<= '2021-01-31'
GROUP BY sales.customer_id


--11. Recreate the table output using the available data


SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
(CASE WHEN sales.order_date >= members.join_date THEN 'Y'
	ELSE 'N' END) as member
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date

--12. Rank all the things:

WITH customer_data AS (
	SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
	(CASE WHEN sales.order_date >= members.join_date THEN 'Y'
		ELSE 'N' END) as member
	FROM sales
	JOIN menu
	ON sales.product_id = menu.product_id
	LEFT JOIN members
	ON sales.customer_id = members.customer_id
)

SELECT *, 
(CASE WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
ELSE NULL
END) AS ranking
FROM customer_data
ORDER BY customer_id, order_date