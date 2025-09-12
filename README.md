# Shopkart_DB

This project contains the database schema and ER diagram for **Shopkart_DB**, a sample e-commerce platform database.  
It is designed for practicing **SQL queries, database design, and data analysis**.

---

## 📂 Files Included
- **schema.sql** → Contains database and table creation scripts.
- **Shopkart_DB_ERD.png** → Entity Relationship Diagram (ERD) for better understanding of the database structure.
- **Shopkart_DB_Excel.xlsx** → Contains the normalized dataset.
- **Basic Analysis.sql** → Contains Basic analytical questions and their queries.
## SHOPKART BASIC ANALYSIS
### Q1. Customer Count : How many unique customers are registered on the platform?
#### **Query** : SQL
SELECT 
    COUNT(*) AS Registered_Customers
FROM
    Customers
WHERE
    Registration_Date IS NOT NULL;
#### **|RESULT|**
#### **|5000  |**
