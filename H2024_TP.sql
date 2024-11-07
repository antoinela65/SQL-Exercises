USE AdventureWorks2019;
GO

/*
=> Question 1
    The sales director comes to your office and requests a filtered list of finished products that can be sold at the present time (i.e., no planned end-of-sale date). She wants only products that are manufactured at AdventureWorks and not purchased from outside. She also wants products with a defined sales price and those with a profit margin of at least 30 dollars.

    She only wants products in black, red, or silver, or products with no color defined in the database.
    She also wants only products with a defined style.
    For unisex products, the list should contain only those with a "low" product class.
    For women’s products, only those with a "medium" class should appear on the list.
    For men’s products, only those with a class of "medium" or "high" should appear on the list.
    Finally, she wants products for which the weight is measured in pounds (LB).

    The sales manager also specifies that the resulting product list should contain only:
    - Product name
    - Product number
    - Displayed price
    - Style
    - Class
    - Color
*/

-- Solution for Question 1

SELECT NAME
    , ProductNumber
    , ListPrice
    , Style
    , Class
    , Color
FROM Production.Product
WHERE FinishedGoodsFlag = 1 -- Finished products
    AND MakeFlag = 1 -- Products manufactured at AdventureWorks
    AND (ListPrice - StandardCost >= 30) -- Profit margin of at least 30 dollars
    AND (Color IN ('Black', 'Red', 'Silver') OR Color IS NULL) -- Product colors
    AND Style IS NOT NULL -- Defined style
    AND (
        (Style = 'U' AND Class = 'L') -- Unisex products of "low" class
        OR (Style = 'W' AND Class = 'M') -- Women’s products of "medium" class
        OR (Style = 'M' AND Class IN ('M', 'H')) -- Men’s products of "medium" or "high" class
    )
    AND WeightUnitMeasureCode = 'LB' -- Product weight measured in pounds
    AND SellEndDate IS NULL -- No planned end-of-sale date
    ;

/*
=> Question 2
    The purchasing director would like to work with you to analyze employees at AdventureWorks who have made purchases. She wants the analysis to focus only on employees who created purchase orders for purchases during the first three quarters of 2013 (January to October 2013).

    She wants the following information:
    - Employee ID
    - Number of purchases made by the employee
    - Total amount of purchases (before taxes and shipping)
    - Average amount of purchases (before taxes and shipping)

    She wants only employees who made purchases during this period to be included in the resulting table.

    Display the result in ascending order by total amount of purchases.
    Ensure the columns in the final result have appropriate names.
*/

-- Solution for Question 2

SELECT EmployeeID
    , COUNT(PurchaseOrderID) AS 'Number of purchases made'
    , SUM(SubTotal) AS 'Total amount of purchases'
    , AVG(SubTotal) AS 'Average amount of purchases'
FROM Purchasing.PurchaseOrderHeader
WHERE (OrderDate between '2013-01-01' and '2013-10-31') and (EmployeeID is not null)
GROUP BY EmployeeID
ORDER BY 'Total amount of purchases';

/*
=> Question 3
    Your colleague mentions that the ProductLine attribute of the product table (Production.Product) only takes the values R, M, T, or S in the database. 
    Is he correct?
    What do you tell him (1 simple sentence)?
    Write a query that allows you to check the number of attributes associated with each value of ProductLine.
*/

-- Solution for Question 3

SELECT ProductLine, COUNT(*) AS NumberOfProducts
FROM Production.Product
WHERE (ProductLine is NOT NULL)
GROUP BY ProductLine;

-- Our colleague is correct to indicate that the ProductLine attribute of the product table only takes the values R, M, T, or S in the database.

/*
=> Question 4

    The HR director overhears your conversation with your colleague and seizes the opportunity to ask for information on the different job titles at AdventureWorks.

    She wants the following information for each job title:
    - Job title
    - Number of employees in the role
    - Average vacation hours
    - Average sick leave hours
    - Average total absence hours (vacation and sick leave)

    She only wants active employees who are paid hourly to be included.

    She also wants to keep only job titles with a total absence hours of 100 or more.

    Make sure to name the columns correctly, following the example below.
    _____________________________________________________________________________________________________________________________________________________
    | Job title       | Number of employees  |  Average vacation hours    | Average sick leave hours | Average total absence hours |
    --------------------------------------------------------------------------------------------------------------------------------------
    |        ...       |       ...                 |           ...                         |        ...                    |        ...                        |
*/

-- Solution for Question 4

SELECT JobTitle AS 'Job title'
, COUNT (BusinessEntityID) AS 'Number of employees'
, AVG ( VacationHours ) AS 'Average vacation hours'
, AVG ( SickLeaveHours ) AS 'Average sick leave hours'
, AVG (VacationHours + SickLeaveHours) AS 'Average total absence hours'
FROM HumanResources.Employee
WHERE (CurrentFlag = 1) and (SalariedFlag = 1)
GROUP BY JobTitle
HAVING (AVG (VacationHours + SickLeaveHours) >= 100)

/*
=> Question 5 
    The sales director now requests your help with a brief analysis concerning credit cards.
    
    She is interested in knowing if certain credit card numbers present in the sales tables are associated with employees, whether they are sellers or not, of AdventureWorks (PersonType).

    She mentions that employees should not be associated with credit cards and wants to check if this is indeed the case.
    She therefore asks you to retrieve the number of credit cards associated with each person type present in the database.

    She wants all person types included, with appropriate column names.

    She also requests that the results be sorted in descending order, displaying the person types with the most credit cards associated first.

    Answer the following questions:
    1) How many credit cards do Individual Customers and Store Contacts have in total?
    2) Are there any person types with no associated credit card?
*/

-- Solution for Question 5

SELECT PersonType AS 'Person Types'
, COUNT (*) AS 'Total number of credit cards'
FROM Person.Person
LEFT JOIN Sales.PersonCreditCard ON Person.Person.BusinessEntityID = Sales.PersonCreditCard.BusinessEntityID
GROUP BY PersonType
ORDER BY 'Total number of credit cards' DESC

/* --- In total, Individual Customers and Store Contacts have 19,118 credit cards. */

SELECT PersonType AS 'Person Types'
, COUNT(DISTINCT cr.CreditCardID) AS 'Number of credit cards'
FROM 
    Person.Person p
LEFT JOIN 
    Sales.Store sc ON p.BusinessEntityID = sc.SalesPersonID
LEFT JOIN 
    Sales.SalesOrderHeader soh ON sc.SalesPersonID = soh.CreditCardID
LEFT JOIN 
    Sales.CreditCard cr ON soh.CreditCardID = cr.CreditCardID
GROUP BY PersonType
HAVING 
    COUNT(DISTINCT cr.CreditCardID) = 0;

/* There are five person types with no credit card: EM, GC, IN, SC, and VC */

/*
=> Question 6

    It’s cleaning time at the AdventureWorks warehouse! The sales director asks for information on the following products:
        1. Product name
        2. Product model name (Production.ProductModel)
        3. Product description in French (see Culture tables)
        4. Number of locations in the warehouse where the product is stored (Production.Location)
        5. Total quantity of this product ordered by customers.

    He only wants this information for finished products, which can be stored in 2 or more warehouse locations. 
    Given the workload, he only wants the 20 products with the highest order quantities for customers to start.
    Note: The same product models and descriptions may appear on multiple lines, as some products have different colors.
*/

-- Solution for Question 6

SELECT TOP 20 
    P.[Name] AS 'Product Name',
    PM.[Name] AS 'Product Model Name',
    PPD.[Description] AS 'Product Description in French',
    COUNT(DISTINCT PL.LocationID) AS 'Number of locations where product is stored',
    SUM(SOD.OrderQty) AS 'Total quantity of product ordered by customers'
FROM 
    Production.Product AS P
INNER JOIN 
    Production.ProductModel AS PM ON P.ProductModelID = PM.ProductModelID
INNER JOIN 
    Production.ProductDescription AS PPD ON PPD.ProductDescriptionID = PPD.ProductDescriptionID
INNER JOIN 
    Production.WorkOrder AS WO ON P.ProductID = WO.ProductID 
INNER JOIN 
    Production.WorkOrderRouting AS WOR ON WO.WorkOrderID = WOR.WorkOrderID 
INNER JOIN 
    Production.[Location] AS PL ON WOR.LocationID = PL.LocationID
INNER JOIN 
    Sales.SalesOrderDetail AS SOD ON P.ProductID = SOD.ProductID
INNER JOIN 
	Production.ProductModelProductDescriptionCulture AS PPPC ON PPPC.CultureID = PPPC.CultureID

WHERE 
	P.FinishedGoodsFlag = 1 and PL.LocationID >= 2 and CultureID = 'FR'
GROUP BY 
    P.[Name], PM.[Name],PPD.[Description]
ORDER BY 
    SUM(SOD.OrderQty) DESC
/*
=> Question 7

    Your colleagues would like to compare the performance of stores in 2012.
    They want to know the sales in dollars (including taxes and delivery fees) per store. 
    They are only interested in in-store sales (in person).
    They only want sales that have not been rejected or canceled.

    The result should have the following three columns (exact names):
        - StoreID of the store
        - Store name
        - Sales in 2012

    In the [Sales in 2012] column, display amounts rounded to two decimal places with a thousand separator.
    Example: 418802.4507 should appear as 418,802.45 or 418 802.45. Add a dollar sign.

    Ensure the information is presented as requested, with correctly named columns.
    Results should be sorted alphabetically by store name.
*/

-- Solution for Question 7

SELECT 
    SC.StoreID AS 'StoreID of the store',
    SS.[Name] AS 'Store name',
    FORMAT(SUM(SOH.TotalDue), '#,0.00') AS 'Sales in 2012'
FROM 
    Sales.SalesOrderHeader AS SOH
INNER JOIN 
    Sales.Customer AS SC ON SOH.CustomerID = SC.CustomerID
INNER JOIN 
    Sales.Store AS SS ON SC.StoreID = SS.BusinessEntityID
WHERE 
    YEAR(SOH.OrderDate) = 2012
    AND OnlineOrderFlag = 0
GROUP BY 
    SC.StoreID, SS.[Name]
ORDER BY 
    SS.[Name];


/*
=> Question 8

    Back to work on Monday morning, your boss has a new request. He heard that you are familiar with data on scrapped (discarded) products and has a question about them.

    He would like to have a list of products (product names) that were scrapped during production, along with the explicit reason for which they were scrapped and the quantity discarded. By explicit, he means he does not want IDs in the list, as he cannot interpret them. He also wants to know, by product and scrapping reason combination, the monetary loss incurred by producing these products, as well as the potential profit lost, i.e., the profit that could have been realized if these products had been manufactured without errors and sold at the listed price.

    For columns representing amounts, display amounts rounded to two decimal places with a thousand separator.
    Example: 418802.4507 should appear as 418,802.45 or 418 802.45. Add a dollar sign.

    He also mentions that he only wants the requested information in the resulting table (no more, no less).

    Additionally, he only wants products that were manufactured in 2013 and where the loss caused by production costs is $150 or more.
*/

-- Solution for Question 8

SELECT 
    P.[Name] AS 'Product name',
    PR.[Name] AS 'Explicit scrapping reason',
    SUM(WO.ScrappedQty) AS 'Quantity scrapped',
    FORMAT(SUM(P.StandardCost * WO.ScrappedQty), '#,0.00') AS 'Monetary loss from production',
    FORMAT(SUM((P.ListPrice - P.StandardCost) * WO.ScrappedQty), '#,0.00') AS 'Potential profit lost'
FROM 
    Production.Product AS P
INNER JOIN 
    Production.WorkOrder AS WO ON WO.ProductID = P.ProductID
INNER JOIN 
    Production.ScrapReason AS PR ON PR.ScrapReasonID = WO.ScrapReasonID
WHERE 
    YEAR(WO.StartDate) = 2013
GROUP BY 
    P.[Name], PR.[Name], WO.ScrappedQty
HAVING 
    SUM(P.StandardCost * WO.ScrappedQty) >= 150
ORDER BY 
    P.[Name], PR.[Name];


/*
=> Question 9

    The sales director would like information on the effort and costs associated with manufacturing various products per work order (Work Order).
    He wants a list of work orders with:
        - Work order ID
        - Name of the associated products (the same product may be manufactured on multiple work orders).
        - Quantity of the product to be manufactured per work order.
        - Total manufacturing hours required per work order.
        - Number of steps required in the manufacturing process per work order.
        - Estimated total manufacturing cost per work order.
        - Actual total manufacturing cost per work order.
        - Error between estimated and actual manufacturing costs per work order.

    Have any work orders exceeded the estimated cost?
*/

-- Solution for Question 9

SELECT 
    PWO.WorkOrderID AS 'Work order ID',
    P.[Name] AS 'Associated product name',
    PWO.OrderQty AS 'Quantity of product manufactured',
    SUM(PWOR.ActualResourceHrs) AS 'Total manufacturing hours',
    COUNT(PWOR.OperationSequence) AS 'Number of steps in manufacturing process',
    SUM(PWOR.PlannedCost) AS 'Estimated total manufacturing cost',
    SUM(PWOR.ActualCost) AS 'Actual total manufacturing cost',
    ABS(PWOR.ActualCost - PWOR.PlannedCost) AS 'Error between estimated and actual cost'
FROM 
    Production.WorkOrderRouting AS PWOR
INNER JOIN 
    Production.WorkOrder AS PWO ON PWO.OrderQty = PWO.OrderQty
INNER JOIN 
    Production.Product AS P ON P.[Name] = P.[Name] 
GROUP BY 
    PWO.WorkOrderID, P.[Name], PWO.OrderQty, PWOR.ActualResourceHrs, PWOR.OperationSequence, PWOR.PlannedCost, PWOR.ActualCost, PWOR.ActualCost - PWOR.PlannedCost;

/*
=> Question 10

    Your new friend for life, the CEO of AdventureWorks, comes to you again. He mentions that he finds it hard to believe that AdventureWorks sells discounted products. You want to prove otherwise, showing that many products are sold at a discount. You need to write a query to support your viewpoint. The results should be formatted as follows:
    
        - Discount type
        - Description of the discount itself
        - Group to whom the discount applies (Customer or Reseller)
        - Quantity of products sold per discount type, labeled as 'Quantity of products sold at discount'
        - Amount of products sold per discount type, labeled as 'Amount of products sold at discount'. Monetary amounts should be displayed with 2 decimal places followed by a "$" sign (e.g., 10.00$).
    
    Sort the results in ascending order by discount type and description.
*/

-- Solution for Question 10

SELECT 
    SO.[Type] AS 'Discount type',
    SO.[Description] AS 'Discount description',
    SO.[Category] AS 'Group to whom the discount applies',
    SUM(SOD.OrderQty) AS 'Quantity of products sold at discount',
    FORMAT(SUM(SOD.UnitPrice - SOD.UnitPriceDiscount), '#,0.00$') AS 'Amount of products sold at discount'
FROM 
    Sales.SalesOrderDetail AS SOD
INNER JOIN 
    Sales.SpecialOffer AS SO ON SO.SpecialOfferID = SOD.SpecialOfferID
INNER JOIN 
    Sales.SpecialOfferProduct AS SOP ON SOP.SpecialOfferID = SO.SpecialOfferID
GROUP BY 
    SO.[Type], SO.[Description], SO.[Category]
ORDER BY 
    1, 2 ASC;


/*
=> Question 11

    The sales director explains that the company is struggling to keep track of products deleted from the system. He asks you to create a mechanism to store a record of all products deleted from the Production.Product table.

    Create a trigger named DeletedProduct and a new table DeletedProductHistory to keep the history of products deleted from the Production.Product table.

    Each time a product is deleted from the Production.Product table, we want to store in the DeletedProductHistory table the following attributes:
        - Product ID
        - Product name
        - Whether the product is manufactured or purchased at AdventureWorks (MakeFlag)
        - Product line
        - Deletion date

    ***
    The deletion date should be the SQL Server date at the time of deletion.
    ***

    You can use the following instructions to test your code without having to delete an existing row:

    --INSERT DUMMY VALUES ROW
    INSERT INTO Production.Product (Name,ProductNumber,MakeFlag,FinishedGoodsFlag,SafetyStockLevel,ReorderPoint,StandardCost,ListPrice,DaysToManufacture,Style,SellStartDate,rowguid,ModifiedDate)
    VALUES ('TestDelete','ProductNumberTestDelete',1,1,1,1,1,1,1,'M','2018-01-01',NEWID(),'2018-01-01');

    --DELETE IT
    DELETE FROM Production.Product WHERE Name='TestDelete';

    --CHECK TABLE
    SELECT * FROM DeletedProductHistory;
*/

-- Create the DeletedProductHistory table
DROP TABLE IF EXISTS DeletedProductHistory;
GO

CREATE TABLE DeletedProductHistory (
    ProductID        INT             PRIMARY KEY,
    ProductName      NVARCHAR(250),
    MakeFlag         BIT,
    ProductLine      NVARCHAR(250), 
    DeletionDate     DATETIME
);

-- Delete the existing trigger if it exists
DROP TRIGGER IF EXISTS Production.DeletedProduct;
GO

-- Create the DeletedProduct trigger
CREATE TRIGGER Production.DeletedProduct
ON Production.Product
AFTER DELETE
AS
BEGIN
    INSERT INTO DeletedProductHistory 
    (
        ProductID, 
        ProductName, 
        MakeFlag, 
        ProductLine, 
        DeletionDate
    )
    SELECT 
        ProductID,
        Name,
        MakeFlag,
        ProductLine,
        GETDATE()
    FROM deleted;
END;

-- INSERT DUMMY VALUES ROW for testing
INSERT INTO Production.Product (Name,ProductNumber,MakeFlag,FinishedGoodsFlag,SafetyStockLevel,ReorderPoint,StandardCost,ListPrice,DaysToManufacture,Style,SellStartDate,rowguid,ModifiedDate)
VALUES ('TestDelete','ProductNumberTestDelete',1,1,1,1,1,1,1,'M','2018-01-01',NEWID(),'2018-01-01');

-- DELETE IT to trigger and verify the log entry
DELETE FROM Production.Product WHERE Name='TestDelete';

-- CHECK TABLE to see results
SELECT * FROM DeletedProductHistory;


/*
=> Question 12

    AdventureWorks places orders with suppliers to acquire the products it needs to manufacture its own products. For all orders that AdventureWorks has placed with its suppliers, display the total billed amount (Total Due) per supplier for the third quarter of 2013.

    Include the supplier’s credit rating in the resulting table. Note, we do not want the numeric value, but rather the associated definition (1 = Superior, etc.). Look in the properties and documentation of AdventureWorks for this information.

    Use two methods to display the credit rating definition.
    First, display the result using a CASE statement.
    In the same query, display the result using a user-defined function named udfCreditRating.

    The query should display only the following attributes:
        - Supplier ID
        - Supplier name
        - Supplier’s credit rating (definition using CASE)
        - Supplier’s credit rating (definition using the function)
        - Total amount due per supplier

    Display the results with suppliers having the best credit rating first, followed by the next best, etc., and within each rating, sort alphabetically by supplier name.
    **Provide the code to create the function first, then the query for the final result.**
*/

-- Create the udfCreditRating function
DROP FUNCTION IF EXISTS udfCreditRating;

CREATE FUNCTION udfCreditRating(@CreditRating INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @RatingDefinition NVARCHAR(50);
    
    SET @RatingDefinition = 
        CASE @CreditRating
            WHEN 1 THEN 'Superior'
            WHEN 2 THEN 'Excellent'
            WHEN 3 THEN 'Above average'
            WHEN 4 THEN 'Average'
            WHEN 5 THEN 'Below average'
            ELSE 'Unknown'
        END;
    
    RETURN @RatingDefinition;
END;
GO

-- Query to retrieve supplier information and their orders from the third quarter of 2013
SELECT 
    P.BusinessEntityID AS SupplierID,
    Name AS SupplierName,
    CASE CreditRating
        WHEN 1 THEN 'Superior'
        WHEN 2 THEN 'Excellent'
        WHEN 3 THEN 'Above average'
        WHEN 4 THEN 'Average'
        WHEN 5 THEN 'Below average'
        ELSE 'Unknown'
    END AS CreditRating_Case,
    dbo.udfCreditRating(CreditRating) AS CreditRating_UDF,
    SUM(PO.TotalDue) AS TotalDue
FROM 
    Purchasing.PurchaseOrderHeader AS PO
INNER JOIN 
    Purchasing.Vendor AS V ON PO.VendorID = V.BusinessEntityID
INNER JOIN 
    Person.BusinessEntity AS P ON V.BusinessEntityID = P.BusinessEntityID
WHERE 
    YEAR(PO.OrderDate) = 2013 AND DATEPART(QUARTER, PO.OrderDate) = 3
GROUP BY 
    P.BusinessEntityID, Name, CreditRating
ORDER BY 
    CreditRating_Case DESC, SupplierName;

GO

/*
=> Question 13

    Your new best friend, the CEO of AdventureWorks, is now interested in details about the highest sales recorded by AdventureWorks in the last quarter of 2013. He requests a view that would give the following details for all sales with a total due in the last quarter of 2013 that is greater than the average total due for that quarter:
    
        - Order number
        - Total due (including taxes, shipping, etc.)
        - Order date
        - Identification (ID) of the salesperson who made the sale, along with their first and last name, all in one cell formatted as 'ID, FirstName LastName'
        - Total quantity of products included in the order (OrderQty)
    
    He mentions that he only wants details of these sales and that he wants the view to be named VW_MeilleuresVentes.
*/

-- Solution for Question 13

DROP VIEW IF EXISTS VW_MeilleuresVentes;
GO

CREATE VIEW VW_MeilleuresVentes AS
SELECT 
    SOH.SalesOrderID AS OrderNumber,
    SOH.TotalDue,
    SOH.OrderDate,
    CONCAT(SalesPersonID, ', ', FirstName, ' ', LastName) AS SalesPerson,
    SUM(SOD.OrderQty) AS TotalQuantity
FROM 
    Sales.SalesOrderHeader AS SOH
JOIN 
    Sales.SalesPerson AS SP ON SOH.SalesPersonID = SP.BusinessEntityID
JOIN
    Sales.SalesOrderDetail AS SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN
    Person.Person AS P ON SP.BusinessEntityID = P.BusinessEntityID
WHERE
    YEAR(SOH.OrderDate) = 2013 
    AND DATEPART(QUARTER, SOH.OrderDate) = 4
    AND SOH.TotalDue > (
        SELECT AVG(SOH.TotalDue)
        FROM Sales.SalesOrderHeader AS SOH
        WHERE YEAR(SOH.OrderDate) = 2013 
        AND DATEPART(QUARTER, SOH.OrderDate) = 4
    )
GROUP BY 
    SOH.SalesOrderID, SOH.TotalDue, SOH.OrderDate, SalesPersonID, FirstName, LastName;

GO

-- CHECK TABLE
SELECT * FROM VW_MeilleuresVentes;


/*
=> Question 14

    The sales director would also like to know which stores (Store) had a total ordered amount (before taxes and shipping) in the first quarter of 2014 that is higher than the average ordered amount (before taxes and shipping) in the last quarter of 2013.
    He mentions that he wants only in-store sales in the list.

    The resulting list should include only the store ID and name, ordered from smallest to largest store ID.
*/

-- Solution for Question 14

SELECT 
    BusinessEntityID AS StoreID,
    Name AS StoreName
FROM 
    Sales.SalesOrderHeader AS SOH
JOIN 
    Sales.Customer AS C ON SOH.CustomerID = C.CustomerID
JOIN 
    Sales.Store AS S ON C.StoreID = S.BusinessEntityID
WHERE 
    SOH.OrderDate >= '2014-01-01' AND SOH.OrderDate < '2014-04-01'
    AND SOH.TotalDue > (
        SELECT AVG(TotalDue)
        FROM Sales.SalesOrderHeader
        WHERE YEAR(OrderDate) = 2013 AND DATEPART(QUARTER, OrderDate) = 4
        AND CustomerID IN (
            SELECT CustomerID
            FROM Sales.Customer
            WHERE StoreID IS NOT NULL
        )
    )
ORDER BY 
    S.BusinessEntityID;


/*
=> Question 15

    Write a scalar function to return the profit per product (ListPrice - StandardCost).
    This function should take StandardCost and ListPrice as inputs.

    The function should be named: dbo.udfProductProfit.
    Ensure to delete the function if it already exists.

    Test your function with the following query:
    SELECT   
        ProductID,
        StandardCost,
        ListPrice,
        dbo.udfProductProfit(StandardCost, ListPrice) as Profit
    FROM Production.Product
    WHERE StandardCost > 0
*/

-- Drop the function if it exists
IF OBJECT_ID('dbo.udfProductProfit', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.udfProductProfit;
END
GO

-- Create the scalar function dbo.udfProductProfit
CREATE FUNCTION dbo.udfProductProfit
(
    @StandardCost DECIMAL(18, 2),
    @ListPrice DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @Profit DECIMAL(18, 2);
    
    SET @Profit = @ListPrice - @StandardCost;

    RETURN @Profit;
END
GO

-- Test the function using a SELECT query
SELECT   
    ProductID,
    StandardCost,
    ListPrice,
    dbo.udfProductProfit(StandardCost, ListPrice) AS Profit
FROM 
    Production.Product
WHERE 
    StandardCost > 0;
