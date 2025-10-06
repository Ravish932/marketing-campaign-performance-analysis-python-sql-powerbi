use PortfolioProject_MarketingAnalytics

SELECT * FROM products


-- Query to Categorize Products based on their Price.
SELECT 
	ProductID,
	ProductName,
	Price,
	CASE
		WHEN price < 50 THEN 'Low'
		WHEN price BETWEEN 50 AND 200 THEN 'Medium'
		ELSE 'High'
	END AS PriceCategory
FROM products


-- SQL Statement to Join Customers with Geography to enrich customer data with geographic information
SELECT 
	c.CustomerID,
	c.CustomerName,
	c.Email,
	c.Gender,
	c.Age,
	g.Country,
	g.City
FROM 
	Customers AS c
LEFT JOIN
	geography AS g
ON c.GeographyID = g.GeographyID
	

-- Query to clean WhiteSpace issue in the Review Text Column

SELECT * FROM customer_reviews

SELECT 
	ReviewID,
	CustomerID,
	ProductID,
	ReviewDate,
	Rating,
	-- Cleans up the ReviewText by replacing double space with single space to ensure the text is more redable and standardize.
	REPLACE(ReviewText,'  ', ' ') AS ReviewText
FROM customer_reviews



-- Query to clean and normalize the engagement_data_table
SELECT 
    EngagementID,  
    ContentID,  
	CampaignID, 
    ProductID, ViewsClicksCombined, 
    UPPER(REPLACE(ContentType, 'Socialmedia', 'Social Media')) AS ContentType,  -- Replaces "Socialmedia" with "Social Media" and then converts all ContentType values to uppercase
    LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) -1) AS Views,  -- Extracts the Views part from the ViewsClicksCombined column by taking the substring before the '-' character
    RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,  -- Extracts the Clicks part from the ViewsClicksCombined column by taking the substring after the '-' character
    Likes,  -- Selects the number of likes the content received
  -- Converts the EngagementDate to the dd.mm.yyyy format
    FORMAT(CONVERT(DATE, EngagementDate), 'dd-MM-yyyy') AS EngagementDate  -- Converts and formats the date as dd.mm.yyyy
FROM 
    engagement_data  
	WHERE 
    ContentType != 'Newsletter';  

	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM customer_journey

WITH Duplicate_Record AS(
	SELECT
		JourneyID,
		CustomerID,
		ProductID,
		VisitDate,
		Stage,
		Action,
		Duration,
		ROW_NUMBER() OVER(PARTITION BY JourneyID, CustomerID, ProductID, VisitDate, Stage, Action
		ORDER BY Duration) AS Row_Num
	FROM customer_journey
	)

SELECT * FROM Duplicate_Record




-- Common Table Expression (CTE) to identify and tag duplicate records

WITH DuplicateRecords AS (
    SELECT 
        JourneyID,
        CustomerID,  
        ProductID,  
        VisitDate,  
        Stage,  
        Action,  
        Duration,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action  
            ORDER BY JourneyID  
        ) AS row_num  
		FROM 
        customer_journey  )

-- Select all records from the CTE where row_num > 1, which indicates duplicate entries
    
SELECT *
FROM DuplicateRecords
WHERE row_num > 1  
ORDER BY JourneyID

-- Outer query selects the final cleaned and standardized data
    
SELECT 
    JourneyID,  
    CustomerID,
    ProductID, 
    VisitDate,  
    Stage,
    Action,  -- Selects the action taken by the customer (e.g., View, Click, Purchase)
    COALESCE(Duration, avg_duration) AS Duration  -- Replaces missing durations with the average duration for the corresponding date
FROM 
    (
        -- Subquery to process and clean the data
        SELECT 
            JourneyID,  -- Selects the unique identifier for each journey to ensure data traceability
            CustomerID,  -- Selects the unique identifier for each customer to link journeys to specific customers
            ProductID,  -- Selects the unique identifier for each product to analyze customer interactions with different products
            VisitDate,  -- Selects the date of the visit to understand the timeline of customer interactions
            UPPER(Stage) AS Stage,  -- Converts Stage values to uppercase for consistency in data analysis
            Action,  -- Selects the action taken by the customer (e.g., View, Click, Purchase)
            Duration,  -- Uses Duration directly, assuming it's already a numeric type
            AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,  -- Calculates the average duration for each date, using only numeric values
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action  -- Groups by these columns to identify duplicate records
                ORDER BY JourneyID  -- Orders by JourneyID to keep the first occurrence of each duplicate
            ) AS row_num  -- Assigns a row number to each row within the partition to identify duplicates
        FROM 
            dbo.customer_journey  -- Specifies the source table from which to select the data
    ) AS subquery  -- Names the subquery for reference in the outer query
WHERE 
    row_num = 1;  -- Keeps only the first occurrence of each duplicate group identified in the subquery
	
	

