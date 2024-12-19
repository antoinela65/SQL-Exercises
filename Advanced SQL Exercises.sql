
/*
	Question #1 :
		a) 

		The VP of Sales at AdventureWorks comes to you and mentions that he would like to learn more about sales made
		in the North American territory.

		He asks you to produce a report of the total sales by North American sales territory AND by product category. Additionally,
		he wants the amounts to be displayed in a typical monetary format (e.g., one million dollars would appear as:
		1,000,000.00$). Finally, he would like the report to be displayed in alphabetical order by the sales territory name and product category.

		Notes:
		- Add descriptive column names to your report; see the expected result excerpt below!
		- The absence of an "official" subcategory will be considered a subcategory itself.
		- Divide the monetary format task into two parts: one for the numeric part (1,000,000.00) and another for adding the dollar sign ($).
		- AdventureWorks stores its sales in USD, regardless of the country of sale, so there is no need for currency conversion.
		- Ensure you select the correct column for calculating total sales based on the joins, or the results will be incorrect!

		Expected result excerpt:
		Country             Category          Total Sales
		------------------ ---------------- -------------------
		Canada             Accessories       221,505.20$
		Canada             Bikes             13,457,682.98$
		Canada             Clothing          432,112.25$
		Canada             Components        2,244,470.02$
		Central            Accessories       46,296.64$
		Central            Bikes             6,761,069.95$
		Central            Clothing          154,237.59$
		Central            Components        947,404.83$
		Northeast          Accessories       51,001.72$
		...
*/

Use AdventureWorks2019
GO

SELECT 
    ST.Name AS [Country],  -- Sales territory name
    PC.Name AS [Category],  -- Product category
    FORMAT(SUM(SOD.LineTotal), 'N2') + '$' AS [Total Sales]  -- Total sales formatted in $ with two decimals
FROM 
    Sales.SalesOrderDetail AS SOD
INNER JOIN 
    Sales.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
INNER JOIN 
    Sales.SalesTerritory AS ST ON SOH.TerritoryID = ST.TerritoryID
INNER JOIN 
    Production.Product AS P ON SOD.ProductID = P.ProductID
INNER JOIN 
    Production.ProductSubcategory AS PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
INNER JOIN 
    Production.ProductCategory AS PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE 
    ST.[Group] = 'North America'  -- Filter sales in North America
GROUP BY 
    ST.Name,  -- Group by sales territory
    PC.Name  -- Group by product category
ORDER BY 
    ST.Name ASC,  -- Sort alphabetically by sales territory
    PC.Name ASC;  -- Sort alphabetically by product category


/*
		b)

		The VP of Sales likes the report but realizes it would be more relevant to display it based on the total sales in descending order.
		Update your query from Question #1a and change the sorting order. Does everything look correct in the display?

		- If everything is normal, indicate the Country/Category pair with the highest total sales.
		- If there's an issue with the display, explain the cause of the problem. Without actually writing another SQL query,
		  describe what you would need to do to sort the results as requested by the VP.
*/

SELECT 
    ST.Name AS [Country],  -- Sales territory name
    PC.Name AS [Category],  -- Product category
    FORMAT(SUM(SOD.LineTotal), 'N2') + '$' AS [Total Sales]  -- Total sales formatted in $ with two decimals
FROM 
    Sales.SalesOrderDetail AS SOD
INNER JOIN 
    Sales.SalesOrderHeader AS SOH ON SOD.SalesOrderID = SOH.SalesOrderID
INNER JOIN 
    Sales.SalesTerritory AS ST ON SOH.TerritoryID = ST.TerritoryID
INNER JOIN 
    Production.Product AS P ON SOD.ProductID = P.ProductID
INNER JOIN 
    Production.ProductSubcategory AS PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
INNER JOIN 
    Production.ProductCategory AS PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE 
    ST.[Group] = 'North America'  -- Filter sales in North America
GROUP BY 
    ST.Name,  -- Group by sales territory
    PC.Name  -- Group by product category
ORDER BY 
    SUM(SOD.LineTotal) DESC,  -- Sort by total sales in descending order
    ST.Name ASC,  -- Sort alphabetically by sales territory (if tied)
    PC.Name ASC;  -- Sort alphabetically by product category (if tied)

	-- Response: The pair Southwest (Country) and Bikes (Category) has the highest total sales with an amount of 20,803,673.94$.

/*
	Question #2 :

		The VP of Sales is worried about the performance of the product documentation department and asks for supporting data.
*/

-- Part A
SELECT 
    PC.ProductCategoryID,  -- Product Category ID
    PC.Name AS [Name],  -- Product Category Name
    COUNT(DISTINCT P.ProductID) AS [Products with Documentation]  -- Count of products with documentation
FROM 
    Production.Product AS P
INNER JOIN 
    Production.ProductSubcategory AS PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
INNER JOIN 
    Production.ProductCategory AS PC ON PSC.ProductCategoryID = PC.ProductCategoryID
INNER JOIN 
    Production.ProductModel AS PM ON P.ProductModelID = PM.ProductModelID
INNER JOIN
    Production.ProductDocument AS PD ON P.ProductID = PD.ProductID 
GROUP BY 
    PC.ProductCategoryID, 
    PC.Name
ORDER BY 
    PC.ProductCategoryID;

-- Part B
SELECT 
    COUNT(P.ProductID) AS [Sellable Products without Documentation]
FROM 
    Production.Product AS P
INNER JOIN 
    Production.ProductModel AS PM ON P.ProductModelID = PM.ProductModelID
WHERE 
    P.FinishedGoodsFlag = 1  -- The product is a finished good
    AND P.DiscontinuedDate IS NULL  -- The product is not discontinued
    AND P.SellEndDate IS NULL  -- The product does not have an end date for sale
    AND (PM.CatalogDescription IS NULL AND PM.Instructions IS NULL);  -- The product lacks documentation



/*
	Question #3 :

		You want to compare the performance of salespeople for 2012, 2013, and 2014.
		You want to know the sales (in dollars, excluding taxes and shipping costs), by salesperson, by year.
		You want to see the names and identifiers of the salespeople.
		You are only interested in in-store sales.
		The salesperson's name (first and last) should be in a single column.

		In the [Sales] column, display the amounts without decimals and with a thousands separator.
		Example: 418802.4507 should appear as: 418,802 or 418 802.

		Include an ORDER BY clause by salesperson name and year.

		Expected result excerpt:

		Salesperson ID   Salesperson Name   Year       Total Sales
		---------------- ------------------ --------- ----------------
		283              David Campbell     2012       1,615,483
		283              David Campbell     2013       2,315,815
		283              David Campbell     2014         997,720
		278              Garrett Vargas     2012       1,295,776
		278              Garrett Vargas     2013       1,405,679
		278              Garrett Vargas     2014         447,752
		289              Jae Pak            2012         999,823
		...
*/

SELECT 
    SP.BusinessEntityID AS [Salesperson ID], 
    CONCAT(P.FirstName, ' ', P.LastName) AS [Salesperson Name],
    YEAR(SOH.OrderDate) AS [Year],
    FORMAT(SUM(SOH.SubTotal), 'N0') AS [Total Sales]
FROM 
    Sales.SalesOrderHeader AS SOH
INNER JOIN 
    Sales.SalesPerson AS SP ON SOH.SalesPersonID = SP.BusinessEntityID
INNER JOIN 
    HumanResources.Employee AS E ON SP.BusinessEntityID = E.BusinessEntityID 
INNER JOIN 
    Person.Person AS P ON E.BusinessEntityID = P.BusinessEntityID 
INNER JOIN 
    Sales.Customer AS C ON SOH.CustomerID = C.CustomerID 
INNER JOIN 
    Sales.Store AS S ON C.StoreID = S.BusinessEntityID 
WHERE
    YEAR(SOH.OrderDate) IN (2012, 2013, 2014) 
    AND S.BusinessEntityID IS NOT NULL  -- Filter for in-store sales
    AND SP.BusinessEntityID IS NOT NULL  -- Ensure the sale was made by a salesperson
GROUP BY 
    SP.BusinessEntityID, 
    P.FirstName, 
    P.LastName, 
    YEAR(SOH.OrderDate)
ORDER BY   
    P.FirstName ASC,
    P.LastName ASC,
    YEAR(SOH.OrderDate) ASC;

/*
	Question #4 :

		The HR director at AdventureWorks asks you to analyze employee information to determine if there are potential inequities between genders.
		You are tasked with designing a query to return the following:
			- the different genders of employees at AdventureWorks,
			- the number of employees belonging to each gender,
			- the percentage of employees belonging to each gender,
			- the minimum, maximum, standard deviation, and average hourly rate for employees of each gender,
		sorted by the percentage of employees.

		Consider the following:
			(1)
				All employees have at least one associated hourly rate. However, hourly rates may change over time, and this information
				is retained in AdventureWorks. Use the most recent hourly rate for each employee to calculate the average hourly rate for a gender.
			(2) 
				The data in AdventureWorks is from 2014; gender representation is limited to a binary representation that does not change over time.
*/

SELECT 
    E.Gender AS [Gender],  
    COUNT(E.BusinessEntityID) AS [Employee Count],  
    FORMAT(COUNT(E.BusinessEntityID) * 100.0 / (SELECT COUNT(*) FROM HumanResources.Employee), 'N2') + '%' AS [Percentage of Employees],  
    ROUND(MIN(L.Rate), 2) AS [Minimum Rate],  
    ROUND(MAX(L.Rate), 2) AS [Maximum Rate],  
    ROUND(STDEV(L.Rate), 2) AS [Standard Deviation of Rate],  
    ROUND(AVG(L.Rate), 2) AS [Average Rate]  
FROM 
    HumanResources.Employee AS E
INNER JOIN 
    (SELECT 
        BusinessEntityID, 
        Rate
     FROM HumanResources.EmployeePayHistory AS EPH
     WHERE RateChangeDate = (SELECT MAX(RateChangeDate) 
                             FROM HumanResources.EmployeePayHistory 
                             WHERE BusinessEntityID = EPH.BusinessEntityID)
    ) AS L ON E.BusinessEntityID = L.BusinessEntityID
GROUP BY 
    E.Gender
ORDER BY 
    COUNT(E.BusinessEntityID) DESC; -- Sort by the gender with the highest percentage of employees


/*
Question #5 :

	a) The HR director at AdventureWorks requests a report displaying the rank of each employee compared to their colleagues
	holding the same position in the company, based on the number of vacation hours allowed.
	The report should display employees by job title, with the fewest vacation hours listed first, sorted by job title.

	Expected result excerpt:

	Position                        Employee / ID              Vacation Hours   Rank by Position
	------------------------------- -------------------------- ---------------- -----------------
	Accountant                      Moreland / id : 245       58               1
	Accountant                      Seamans / id : 248        59               2
	Accounts Manager                Liu / id : 241            57               1
	Accounts Payable Specialist     Tomic / id : 246          63               1
	Accounts Payable Specialist     Sheperdigian / id : 247   64               2
	Accounts Receivable Specialist  Poe / id : 242            60               1
	Accounts Receivable Specialist  Spoon / id : 243          61               2
	Accounts Receivable Specialist  Walton / id : 244         62               3
	Application Specialist          Bueno / id : 272          71               1
	...
*/

SELECT
	e.JobTitle AS [Position],
	CONCAT(p.LastName, ' / id : ', p.BusinessEntityID) AS [Employee / ID],
	e.VacationHours AS [Vacation Hours],
	RANK() OVER (PARTITION BY e.JobTitle        -- Partition by Job Title
				 ORDER BY e.VacationHours ASC)  -- Order by Vacation Hours in ascending order
				 AS [Rank by Position]         -- Rank employees within each Job Title
FROM HumanResources.Employee AS e
INNER JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
ORDER BY e.JobTitle;

/*
	b) The HR director asks to limit the report content to employees with the fewest vacation hours allowed
	by job title. The report should still be sorted by job title.

	Expected result excerpt:

	Position                        Employee / ID              Vacation Hours
	------------------------------- -------------------------- ----------------
	Accountant                      Moreland / id : 245       58
	Accounts Manager                Liu / id : 241            57
	Accounts Payable Specialist     Tomic / id : 246          63
	Accounts Receivable Specialist  Poe / id : 242            60
	Application Specialist          Bueno / id : 272          71
	...
*/

-- Subquery required because RANK cannot be used in the WHERE clause
SELECT
	subQ.JobTitle AS [Position],
	CONCAT(subQ.LastName, ' / id : ', subQ.BusinessEntityID) AS [Employee / ID],
	subQ.VacationHours AS [Vacation Hours]
FROM (
	SELECT
		e.BusinessEntityID,
		e.JobTitle,
		p.LastName,
		e.VacationHours,
		RANK() OVER (PARTITION BY e.JobTitle ORDER BY e.VacationHours ASC) AS [Rank by Position]
	FROM HumanResources.Employee AS e
	INNER JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
) AS subQ
WHERE subQ.[Rank by Position] = 1
ORDER BY subQ.JobTitle;

/*
	c) The HR director realizes that to better understand employee rankings by vacation hours, 
	he will need to generate multiple similar reports. He wants to decide:
	- The number of ranks to display per position (1, 2, 3, ...).
	- The sorting order to generate the ranks (ascending for the best, descending for the worst).

	Since his SQL knowledge is limited, propose a function definition that lets him generate reports himself.

	1. Function call: SELECT * FROM EmployeeRank(3, 0) ORDER BY [Position]
	   Produces a report with the top 3 employees with the fewest vacation hours per position.
	   Example:

	Position                        Employee / ID             Vacation Hours   Rank by Position
	------------------------------- ------------------------- ---------------- -----------------
	Accountant                      Moreland / id : 245      58               1
	Accountant                      Seamans / id : 248       59               2
	...

	2. Function call: SELECT * FROM EmployeeRank(4, 1) ORDER BY [Position]
	   Produces a report with the top 4 employees with the most vacation hours per position.
	   Example:

	Position                        Employee / ID             Vacation Hours   Rank by Position
	------------------------------- ------------------------- ---------------- -----------------
	Accountant                      Seamans / id : 248       59               1
	...
*/

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TIA')
BEGIN
	CREATE DATABASE TIA;
END;
GO

USE TIA;
GO

CREATE OR ALTER FUNCTION EmployeeRank(@maxRank TINYINT, @order BIT) RETURNS TABLE
AS
RETURN (
	SELECT
		e.JobTitle AS [Position],
		CONCAT(p.LastName, ' / id : ', p.BusinessEntityID) AS [Employee / ID],
		e.VacationHours AS [Vacation Hours],
		CASE
			WHEN @order = 0 THEN RANK() OVER (PARTITION BY e.JobTitle ORDER BY e.VacationHours ASC)
			ELSE RANK() OVER (PARTITION BY e.JobTitle ORDER BY e.VacationHours DESC)
		END AS [Rank by Position]
	FROM AdventureWorks2022.HumanResources.Employee AS e
	INNER JOIN AdventureWorks2022.Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
	WHERE RANK() <= @maxRank
);
GO

-- Retrieve top 3 employees with the fewest vacation hours per position
SELECT * FROM EmployeeRank(3, 0) ORDER BY [Position];

-- Retrieve top 4 employees with the most vacation hours per position
SELECT * FROM EmployeeRank(4, 1) ORDER BY [Position];

/*
	d) The HR director revisits the report obtained with the function call:
	SELECT * FROM EmployeeRank(3, 0) ORDER BY [Position].
	He would now like to add two additional columns to the report:
	- The number of sick leave hours for each employee displayed in the report.
	- The difference in sick leave hours between an employee and the one ranked directly above them for the same position.
	  (This value should be NULL for the top-ranked employee in each position.)

	Note: You cannot modify the definition of the EmployeeRank function.

	Expected result excerpt:

	Position                        Employee / ID             Vacation Hours   Rank by Position  Sick Leave Hours   Sick Leave Difference with Previous Rank
	------------------------------- ------------------------- ---------------- ----------------- ----------------- -----------------------------------------
	Accountant                      Moreland / id : 245      58               1                 49                NULL
	Accountant                      Seamans / id : 248       59               2                 49                0
	Accounts Manager                Liu / id : 241           57               1                 48                NULL
	Accounts Payable Specialist     Tomic / id : 246         63               1                 51                NULL
	Accounts Payable Specialist     Sheperdigian / id : 247  64               2                 52                1
	...
*/

SELECT
	er.[Position],
	er.[Employee / ID],
	er.[Vacation Hours],
	er.[Rank by Position],
	e.SickLeaveHours AS [Sick Leave Hours],
	e.SickLeaveHours - LAG(e.SickLeaveHours, 1) OVER (PARTITION BY er.[Position] ORDER BY er.[Rank by Position]) AS [Sick Leave Difference with Previous Rank]
FROM AdventureWorks2022.HumanResources.Employee AS e
INNER JOIN TIA.dbo.EmployeeRank(10, 0) AS er
	ON CAST(SUBSTRING(er.[Employee / ID], CHARINDEX(' / id : ', er.[Employee / ID]) + 8, LEN(er.[Employee / ID])) AS INT) = e.BusinessEntityID
ORDER BY [Position];

/*
Question #6 :

	a) The Sales department at AdventureWorks wants to start a recognition program for its employees.
	   Create a query to identify each salesperson by:
	   1) Number of orders they have made,
	   2) Total sales subtotal, and
	   3) Total number of products sold.

	   The report should include:
		- The salesperson's BusinessEntityID,
		- The salesperson's first and last names,
		- The total number of orders,
		- The rank of the salesperson based on the total number of orders (no rank gaps for ties),
		- The total sales amount,
		- The rank of the salesperson based on total sales amount,
		- The total number of products sold,
		- The rank of the salesperson based on the total number of products sold.

	   Expected result excerpt:

	BusinessEntityID  FirstName  LastName  NumberOfOrders  OrderRank  TotalSales       SalesRank  ProdNoTotal  ProdNoRank
	----------------- ---------- --------- --------------- ---------- ---------------- ---------- ------------ ----------
	277               Jillian    Carson    473             1          10,065,803.54    2          7,825        1
	276               Linda      Mitchell  418             2          10,367,007.43    1          7,107        2
	275               Michael    Blythe    450             3           9,293,903.00    3          7,069        3
	...
*/

SELECT
	p.BusinessEntityID,
	p.FirstName,
	p.LastName,
	COUNT(DISTINCT soh.SalesOrderID) AS [NumberOfOrders],
	DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT soh.SalesOrderID) DESC) AS [OrderRank],
	SUM(sod.LineTotal) AS [TotalSales],
	DENSE_RANK() OVER (ORDER BY SUM(sod.LineTotal) DESC) AS [SalesRank],
	COUNT(sod.SalesOrderDetailID) AS [ProdNoTotal],
	DENSE_RANK() OVER (ORDER BY COUNT(sod.SalesOrderDetailID) DESC) AS [ProdNoRank]
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesPerson AS sp ON sp.BusinessEntityID = soh.SalesPersonID
INNER JOIN Person.Person AS p ON p.BusinessEntityID = sp.BusinessEntityID
INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY
	p.BusinessEntityID,
	p.FirstName,
	p.LastName
ORDER BY [NumberOfOrders] DESC;

/*
	b) The Sales director at AdventureWorks wants to personally thank the best-performing salespeople for their loyalty.
	   Using the query developed in part (a), generate a new report displaying only salespeople with at least one rank (OrderRank, SalesRank, ProdNoRank) <= 3.
	   Replace rank values with "Best," "2nd best," or "3rd best" for ranks 1, 2, or 3, respectively. Hide other ranks.

	   Include the salesperson's phone number and its type (e.g., home, work, mobile).
	   Example format:

	BusinessEntityID  FirstName  LastName  Phone Number        OrderRank  SalesRank  ProdNoRank
	----------------- ---------- --------- ------------------- ---------  ---------  ---------
	277               Jillian    Carson    517-555-0117 (Work) Best       2nd best   Best
	276               Linda      Mitchell  883-555-0116 (Work) -          Best       2nd best
	...
*/

SELECT
	SUB_Q.BusinessEntityID,
	SUB_Q.FirstName,
	SUB_Q.LastName,
	CONCAT(pp.PhoneNumber, ' (', ppt.Name, ')') AS [Phone Number],
	CASE [OrderRank]
		WHEN 1 THEN 'Best'
		WHEN 2 THEN '2nd best'
		WHEN 3 THEN '3rd best'
		ELSE '-'
	END AS [OrderRank],
	CASE [SalesRank]
		WHEN 1 THEN 'Best'
		WHEN 2 THEN '2nd best'
		WHEN 3 THEN '3rd best'
		ELSE '-'
	END AS [SalesRank],
	CASE [ProdNoRank]
		WHEN 1 THEN 'Best'
		WHEN 2 THEN '2nd best'
		WHEN 3 THEN '3rd best'
		ELSE '-'
	END AS [ProdNoRank]
FROM (
	SELECT
		p.BusinessEntityID,
		p.FirstName,
		p.LastName,
		COUNT(DISTINCT soh.SalesOrderID) AS [NumberOfOrders],
		DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT soh.SalesOrderID) DESC) AS [OrderRank],
		SUM(sod.LineTotal) AS [TotalSales],
		DENSE_RANK() OVER (ORDER BY SUM(sod.LineTotal) DESC) AS [SalesRank],
		COUNT(sod.SalesOrderDetailID) AS [ProdNoTotal],
		DENSE_RANK() OVER (ORDER BY COUNT(sod.SalesOrderDetailID) DESC) AS [ProdNoRank]
	FROM Sales.SalesOrderHeader AS soh
	INNER JOIN Sales.SalesPerson AS sp ON sp.BusinessEntityID = soh.SalesPersonID
	INNER JOIN Person.Person AS p ON p.BusinessEntityID = sp.BusinessEntityID
	INNER JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
	GROUP BY
		p.BusinessEntityID,
		p.FirstName,
		p.LastName
) AS SUB_Q
INNER JOIN Person.PersonPhone AS pp ON pp.BusinessEntityID = SUB_Q.BusinessEntityID
INNER JOIN Person.PhoneNumberType AS ppt ON pp.PhoneNumberTypeID = ppt.PhoneNumberTypeID
WHERE SUB_Q.[OrderRank] <= 3 OR SUB_Q.[SalesRank] <= 3 OR SUB_Q.[ProdNoRank] <= 3
ORDER BY [FirstName], [LastName];
