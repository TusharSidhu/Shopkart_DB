USE Shopkart;
-- BASIC ANALYSIS --
-- CUSTOMER COUNT : How many customers are registered on the platform? --
SELECT 
    COUNT(*) AS Registered_Customers
FROM
    Customers
WHERE
    Registration_Date IS NOT NULL;
    
-- TOTAL ORDERS : What is the total number of orders placed? --
SELECT 
    COUNT(*) AS Total_Orders
FROM
    Orders;
    
-- REVENUE : What is the total revenue generated from all completed payments? --
SELECT 
    SUM(Total_Amount) AS Total_Revenue
FROM
    Payments
WHERE
    Payment_Status = 'Paid';
    
-- TOP CATEGORIES : Which product category has the highest number of orders? --
SELECT 
    C.Category_ID,
    C.Category_Name,
    COUNT(DISTINCT OI.Order_ID) AS No_of_Orders
FROM
    Category C
        JOIN
    Products P ON C.Category_ID = P.Category_ID
        JOIN
    Order_Items OI ON P.Product_ID = OI.Product_ID
GROUP BY C.Category_ID , C.Category_Name
ORDER BY No_of_Orders DESC
LIMIT 1;

-- TOP PRODUCTS : Which are the top 5 best-selling products by quantity ordered? --
SELECT 
    P.Product_ID,
    P.Product_Name,
    SUM(OI.Quantity) AS Quantity_Ordered
FROM
    Products P
        JOIN
    Order_Items OI ON P.Product_ID = OI.Product_ID
GROUP BY P.Product_ID , P.Product_Name
ORDER BY SUM(OI.Quantity) DESC
LIMIT 5;

-- AVERAGE ORDER VALUE (AOV) : What is the average order value of an order? --
SELECT 
    ROUND(AVG(Order_Total), 2) AS Average_Order_Value
FROM
    Orders;
    
-- PAYMENT METHOD USAGE : What are the most frequently used payment methods? --
SELECT 
    Payment_Method, COUNT(*) AS Methods_Used
FROM
    Payments
GROUP BY Payment_Method
ORDER BY Methods_Used DESC;

-- MONTHLY SALES TREND : What is the total sales amount per month for the year 2024? --
SELECT 
    MONTH(O.Order_Date) AS Month_Num,
    MONTHNAME(O.Order_Date) AS Months,
    SUM(P.Total_Amount) AS Sales_Per_Month
FROM
    Orders O
        JOIN
    Payments P ON O.Order_ID = P.Order_ID
WHERE
    P.Payment_Status = 'Paid'
        AND YEAR(O.Order_Date) = '2024'
GROUP BY Month_Num , Months
ORDER BY Month_Num;

-- REPEAT CUSTOMERS : How many customers placed more than one order? --
SELECT 
    COUNT(*) AS Customers_With_Multiple_Orders
FROM
    (SELECT 
        Customer_ID
    FROM
        Orders
    GROUP BY Customer_ID
    HAVING COUNT(Order_ID) > 1) AS Multiple_Orders;
    
-- HIGH-VALUE CUSTOMERS : Who are the top 10 customers by total spend? --
SELECT 
    C.Customer_ID,
    C.Customer_Name,
    C.Email,
    C.City,
    C.State,
    SUM(P.Total_Amount) AS Total_Spend
FROM
    Customers C
        JOIN
    Orders O ON C.Customer_ID = O.Customer_ID
        JOIN
    Payments P ON O.Order_ID = P.Order_ID
WHERE
    P.Payment_Status NOT IN ('Cancelled' , 'Refunded', 'Failed')
GROUP BY C.Customer_ID , C.Customer_Name , C.Email , C.City , C.State
ORDER BY Total_Spend DESC
LIMIT 10;
