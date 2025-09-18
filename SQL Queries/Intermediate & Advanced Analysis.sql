-- INTERMEDIATE ANALYSIS --
-- CUSTOMER SEGMENTATION BY SPEND : Customers grouped into segments (Low, Medium and High Spenders) based on total spend --
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    C.Email,
    SUM(O.Order_Total) AS Total_Spend,
    CASE
        WHEN SUM(O.Order_Total) > 25000 THEN 'High Spenders'
        WHEN SUM(O.Order_Total) BETWEEN 10000 AND 25000 THEN 'Medium Spenders'
        ELSE 'Low Spenders'
    END AS Customer_Segments
FROM
    Customers C
        JOIN
    Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID , C.Customer_Name , C.Email
ORDER BY C.Customer_ID;

-- CUSTOMER RETENTION : What percentage of customers returned and placed another order within 30 days of their first purchase? --
WITH First_Order AS(
SELECT Customer_ID, MIN(Order_Date) AS First_Order_Date FROM Orders
GROUP BY Customer_ID
),
Repeat_Orders AS(
SELECT O.Customer_ID, FO.First_Order_Date, MIN(O.Order_Date) AS Next_Order_Date
FROM Orders O
JOIN First_Order FO
ON O.Customer_ID = FO.Customer_ID
WHERE O.Order_Date > FO.First_Order_Date
GROUP BY O.Customer_ID, FO.First_Order_Date
)
SELECT ROUND(
(COUNT(CASE WHEN DATEDIFF(Next_Order_Date, First_Order_Date) <= 30 THEN 1 END)/COUNT(*))*100,2
)AS Percentage_Customers_Repeat_Within_30_Days FROM Repeat_Orders;

-- ORDER FREQUENCY DISTRIBUTION : What percentage of customers placed 1 order, 2–5 orders, 6–10 orders, 10+ orders? --
WITH Customer_Order_Count AS(
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    COUNT(O.Order_ID) AS Total_Orders
FROM
    Customers C
        JOIN
    Orders O ON C.Customer_ID = O.Customer_ID
GROUP BY C.Customer_ID , C.Customer_Name
)
SELECT CASE
WHEN Total_Orders = 1 THEN '1 Order'
WHEN Total_Orders BETWEEN 2 AND 5 THEN '2-5 Orders'
WHEN Total_Orders BETWEEN 6 AND 10 THEN '6-10 Orders'
ELSE '10+ Orders'
END AS Order_Bucket,
COUNT(*) AS Customer_Count,
ROUND((COUNT(*) * 100.00/(SELECT COUNT(*) FROM  Customer_Order_Count)),2) AS Percentage_Customers
FROM Customer_Order_Count
GROUP BY 
CASE 
WHEN Total_Orders = 1 THEN '1 Order'
WHEN Total_Orders BETWEEN 2 AND 5 THEN '2-5 Orders'
WHEN Total_Orders BETWEEN 6 AND 10 THEN '6-10 Orders'
ELSE '10+ Orders'
END
ORDER BY MIN(Total_Orders);

-- CATEGORY FREQUENCY DISTRIBUTION : What percentage of total revenue is contributed by each category? --
WITH Category_Revenue AS(
SELECT 
    C.Category_ID,
    C.Category_Name,
    SUM(OI.Quantity * P.Price) AS Revenue_without_GST
FROM
    Category C
        JOIN
    Products P ON C.Category_ID = P.Category_ID
        JOIN
    Order_Items OI ON P.Product_ID = OI.Product_ID
        JOIN
    Orders O ON OI.Order_ID = O.Order_ID
        JOIN
    Payments PY ON O.Order_ID = PY.Order_ID
WHERE
    PY.Payment_Status = 'Paid'
GROUP BY C.Category_ID , C.Category_Name
ORDER BY C.Category_ID
),
Overall_Revenue AS(
SELECT 
    SUM(Revenue_without_GST) AS Total_Revenue
FROM
    Category_Revenue
    )
SELECT 
    CR.Category_ID,
    CR.Category_Name,
    ROUND((CR.Revenue_without_GST / OVR.Total_Revenue) * 100,
            2) AS Revenue_Percentage
FROM
    Category_Revenue CR
        CROSS JOIN
    Overall_Revenue OVR
ORDER BY Revenue_Percentage;

-- PRODUCT PROFITABILITY : Which products contribute the most revenue ? --
SELECT 
    P.Product_ID,
    P.Product_Name,
    SUM(OI.Quantity * P.Price) AS Product_Revenue
FROM
    Products P
        JOIN
    Order_Items OI ON P.Product_ID = OI.Product_ID
GROUP BY P.Product_ID , P.Product_Name
ORDER BY Product_Revenue DESC;

-- AVERAGE TIME BETWEEN ORDERS : On average, how many days does it take for a customer to place their next order? --
WITH Customer_Order_Gaps AS (
    SELECT 
        O.Customer_ID,
        O.Order_ID,
        O.Order_Date,
        LAG(O.Order_Date) OVER (PARTITION BY O.Customer_ID ORDER BY O.Order_Date) AS Prev_Order_Date
    FROM Orders O
    WHERE O.Order_Status = 'Delivered'
)
SELECT 
    ROUND(AVG(DATEDIFF(Order_Date, Prev_Order_Date)), 2) AS Avg_Days_Between_Orders
FROM Customer_Order_Gaps
WHERE Prev_Order_Date IS NOT NULL;

-- PAYMENT SUCCESS VS. FAILURE : What is the failure rate of different payment methods? --
SELECT 
    Payment_Method,
    COUNT(*) AS Total_Payments,
    
    -- Success
    SUM(CASE WHEN Payment_Status = 'Paid' THEN 1 ELSE 0 END) AS Successful_Payments,
    
    -- Failures (excluding Unpaid because COD pending is not failure)
    SUM(CASE WHEN Payment_Status IN ('Failed', 'Refunded', 'Cancelled', 'Partially Paid') 
             THEN 1 ELSE 0 END) AS Failed_Payments,
    
    -- Percentages
    ROUND(SUM(CASE WHEN Payment_Status = 'Paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Success_Percentage,
    ROUND(SUM(CASE WHEN Payment_Status IN ('Failed', 'Refunded', 'Cancelled', 'Partially Paid') THEN 1 ELSE 0 END) 
          * 100.0 / COUNT(*), 2) AS Failure_Percentage
FROM Payments
GROUP BY Payment_Method
ORDER BY Failure_Percentage DESC;

-- ORDER SIZE ANALYSIS : What is the average number of items per order, and how does it differ by category? --
-- Overall Average Number of Items per Order --
SELECT 
    AVG(Item_Count) AS Avg_item_per_order
FROM
    (SELECT 
        OI.Order_ID, SUM(OI.Quantity) AS Item_Count
    FROM
        Order_Items OI
    GROUP BY OI.Order_ID) AS Order_Summary;
-- Average Items per Order by Category --
SELECT 
    C.Category_Name,
    AVG(order_category_items.total_items) AS avg_items_per_order_in_category
FROM (
    SELECT 
        O.Order_ID,
        P.Category_ID,
        SUM(OI.Quantity) AS total_items
    FROM Orders O
    JOIN Order_Items OI ON O.Order_ID = OI.Order_ID
    JOIN Products P ON OI.Product_ID = P.Product_ID
    GROUP BY O.Order_ID, P.Category_ID
) AS order_category_items
JOIN Category C ON order_category_items.Category_ID = C.Category_ID
GROUP BY C.Category_Name
ORDER BY avg_items_per_order_in_category DESC;

-- MONTHLY ACTIVE CUSTOMERS : How many unique customers placed at least one order in each month? --
SELECT 
    DATE_FORMAT(O.Order_Date, '%Y-%m') AS Year_Months,
    COUNT(DISTINCT O.Customer_ID) AS unique_customers
FROM Orders O
GROUP BY DATE_FORMAT(O.Order_Date, '%Y-%m')
ORDER BY Year_Months;

-- HIGH VALUE CATEGORY & CUSTOMER OVERLAP : Which customers spend the most in the highest revenue-generating category?
WITH Category_Revenue AS (
    SELECT 
        P.Category_ID
    FROM Order_Items OI
    JOIN Products P ON OI.Product_ID = P.Product_ID
    GROUP BY P.Category_ID
    ORDER BY SUM(OI.Quantity * P.Price) DESC
    LIMIT 1
)
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    SUM(OI.Quantity * P.Price) AS Total_Spent
FROM Orders O
JOIN Order_Items OI ON O.Order_ID = OI.Order_ID
JOIN Products P ON OI.Product_ID = P.Product_ID
JOIN Customers C ON O.Customer_ID = C.Customer_ID
WHERE P.Category_ID = (SELECT Category_ID FROM Category_Revenue)
GROUP BY C.Customer_ID, C.Customer_Name
ORDER BY Total_Spent DESC;