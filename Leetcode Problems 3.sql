
Type: Union and CTE 

1. Number of Calls Between Two Persons

WITH uniont AS (
    SELECT 
        from_id AS person1,
        to_id AS person2,
        duration
    FROM calls
    WHERE from_id < to_id
    
    UNION ALL
    
    SELECT
        to_id AS person1,
        from_id AS person2,
        duration
    FROM calls
    WHERE to_id < from_id
    
)

SELECT
    person1,
    person2,
    COUNT(*) AS call_count,
    SUM(duration) AS total_duration
FROM uniont
GROUP BY person1, person2;


# Same Question above can be solved using CASE WHEN statements OR IF Function OR Greatest/Least

SELECT
    CASE
        WHEN from_id < to_id THEN from_id
        ELSE to_id
        END AS person1,
    CASE
        WHEN from_id > to_id THEN from_id
        ELSE to_id
        END AS person2,
    COUNT(*) AS call_count,
    SUM(duration) AS total_duration
FROM calls
GROUP BY person1, person2;

# Using if

SELECT
    IF(from_id < to_id, from_id, to_id) AS person1,
    IF(from_id > to_id, from_id, to_id) AS person2,
    COUNT(*) AS call_count,
    SUM(duration) AS total_duration
FROM calls
GROUP BY person1, person2;

# Using greatest/least

SELECT
    LEAST(from_id,to_id) AS person1,
    GREATEST(from_id,to_id) AS person2,
    COUNT(*) AS call_count,
    SUM(duration) AS total_duration
FROM calls
GROUP BY person1, person2;



2. CTE - Average Selling Price

WITH sell_price_table AS
(
SELECT
    u.product_id,
    u.purchase_date,
    u.units,
    p.price,
    u.units * p.price AS sell_price 
FROM UnitsSold u
LEFT JOIN Prices p
ON u.product_id = p.product_id
WHERE u.purchase_date >= p.start_date AND u.purchase_date <= p.end_date
)
SELECT
    product_id,
    ROUND(
        SUM(sell_price) / SUM(units),2
        ) AS average_price
FROM sell_price_table
GROUP BY product_id;

NOTE: Same problem can be solved without using CTE 

SELECT
    u.product_id,
    ROUND(
        SUM(u.units * p.price) / SUM(u.units),2
    ) AS average_price
FROM UnitsSold u
JOIN Prices p
ON u.product_id = p.product_id
AND u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY u.product_id;



Type: Difference from a single ENUM column

1. Apples & Oranges

I. 
SELECT
    sale_date,
    SUM(IF(fruit = "apples",sold_num,sold_num*(-1))) AS diff
FROM sales
GROUP BY sale_date
ORDER BY sale_date;*/

II.
SELECT
    sale_date,
    SUM(
        CASE 
            WHEN fruit = "apples" THEN sold_num ELSE sold_num*(-1)
        END) AS diff
FROM sales
GROUP BY sale_date
ORDER BY sale_date



Type: Involving Dates/Months/Years

1. Monthly Transactions I

SELECT
    SUBSTR(trans_date,1,7) AS month,
    country,
    COUNT(*) AS trans_count,
    SUM(IF(state = "approved",1,0)) AS approved_count,
    SUM(amount) AS trans_total_amount,
    SUM(IF(state = "approved",amount,0)) AS approved_total_amount
FROM Transactions
GROUP BY month, country;


SELECT
    DATE_FORMAT(trans_date,%Y-%m) AS month, # or LEFT(trans_date,7) AS month
    country,
    COUNT(*) AS trans_count,
    SUM(IF(state = "approved",1,0)) AS approved_count,
    SUM(amount) AS trans_total_amount,
    SUM(IF(state = "approved",amount,0)) AS approved_total_amount
FROM Transactions
GROUP BY month, country;




Type: Subquery/Condition in calculation

1. Percentage of Users Attended a Contest

SELECT
    contest_id,
    ROUND(
        100 * COUNT(*) / (SELECT COUNT(*) FROM users),2
    ) AS percentage
FROM register
GROUP BY contest_id
ORDER BY percentage DESC, contest_id;

2. Immediate Food Delivery I

SELECT
    ROUND(100 * SUM(IF(order_date = customer_pref_delivery_date, 1, 0)) / COUNT(*),2) AS immediate_percentage
FROM Delivery;

3. Queries Quality and Percentage

SELECT
    query_name,
    ROUND(AVG(rating/position),2) AS quality,
    ROUND(100*AVG(rating<3),2) AS poor_query_percentage
FROM Queries
GROUP BY query_name;



Type: NOT IN

1. Sellers With No Sales

SELECT
    seller_name
FROM seller
WHERE seller_id NOT IN (
    SELECT
        seller_id
    FROM orders
    WHERE LEFT(sale_date,4) = "2020"
)
ORDER BY seller_name;

NOTE: Same query can be written as a join statement, join statement is usually preferred to over come limitations of NOT IN Clause. Also in join statement, please note year condition is written in join statement and not in where clause to avoid filtering out relevant fields due to order of preference of WHERE Clause

SELECT
    s.seller_name
FROM seller s
LEFT JOIN orders o
ON o.seller_id = s.seller_id AND LEFT(sale_date,4) = "2020" 
WHERE o.order_id IS NULL
ORDER BY s.seller_name
;

 

Type: Subquery for an aggregated column from a single table

1.  Biggest Single Number

SELECT (
    SELECT 
        MAX(num) AS max_num 
    FROM mynumbers 
    GROUP BY num 
    HAVING COUNT(*) = 1 
    ORDER BY max_num DESC LIMIT 1) AS num;

SELECT
    MAX(num) AS num
FROM (
    SELECT
        num 
    FROM mynumbers
    GROUP BY num
    HAVING count(*) = 1
) AS t;



Type: Window Function - Rank()

1. Highest Grade For Each Student

WITH rank_table AS (

    SELECT
        student_id,
        course_id,
        grade,
        RANK() over (PARTITION BY student_id ORDER BY grade DESC, course_id) AS course_rank
    FROM enrollments
)
SELECT
    student_id,
    course_id,
    grade
FROM rank_table
WHERE course_rank = 1;


NOTE: Same query can be written without a window function 

SELECT
    student_id,
    MIN(course_id) AS course_id,
    grade
FROM enrollments
where (student_id, grade) IN (
    SELECT
        student_id,
        MAX(grade) AS grade
    FROM enrollments
    GROUP BY student_id
)
GROUP BY student_id
ORDER BY student_id;
