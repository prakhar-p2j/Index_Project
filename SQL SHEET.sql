# Creating and and Defaulting the ues of databse.

Create database Index_Project;
Show databases;
USE Index_Project;
show tables;

# Creating Table with empty columns. Names of columns are same to CSV/data file for matching.

CREATE TABLE latest_index (
  `Company_Name` VARCHAR(5000),
  `Exchange:Ticker` TEXT,
  `Geographic Locations` TEXT,
  `Industry Classifications` TEXT,
  `Market_Cap_$mm` DOUBLE (15,2),
  `Day_Close_Price (10-5-23) ($)` DOUBLE (15,2),
  `Daily_Volume (10-5-23) (mm)` DOUBLE (15,2),
  `Day_High_Price (10-5-23) ($)` DOUBLE (15,2),
  `Day_Low_Price (10-5-23) ($)` DOUBLE (15,2),
  `Shares_Outstanding (10-5-23) (mm)` TEXT,
  `Operating_Income (FY 2022) ($mm)` DOUBLE (15,2),
  `Revenues (FY 2022) ($mm)` DOUBLE (15,2),
  `Other_Revenues (FY 2022) ($mm)` DOUBLE (15,2)
);
# Checking the table and its columns.
select*from latest_index;
show columns from latest_index;
SELECT COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'latest_index';

-- ALter Tables to change the number size before importing CSV.
ALTER TABLE latest_index
MODIFY COLUMN `Day_Close_Price (10-5-23) ($)` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Market_Cap_$mm` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Day_High_Price (10-5-23) ($)` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Day_Low_Price (10-5-23) ($)` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Shares_Outstanding (10-5-23) (mm)` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Operating_Income (FY 2022) ($mm)` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Revenues (FY 2022) ($mm)` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Other_Revenues (FY 2022) ($mm)` DOUBLE(15,2); -- Adjust the length as per your requirements
ALTER TABLE latest_index
MODIFY COLUMN `Daily_Volume (10-5-23) (mm)` DOUBLE(15,2); -- Adjust the length as per your requirements

# Changing the name of columns. Imported the file with latest figures of stock price (Index Calculation Date: May 10, 2023).

ALTER TABLE latest_index
RENAME COLUMN Market_Cap_$mm TO Market_cap;
ALTER TABLE latest_index
RENAME COLUMN Market_Cap_$mm TO Market_cap;
ALTER TABLE latest_index
RENAME COLUMN `Daily_Volume (10-5-23) (mm)` TO Daily_Volume;
ALTER TABLE latest_index
RENAME COLUMN `Other_Revenues (FY 2022) ($mm)` TO Other_Revenues;
ALTER TABLE latest_index
RENAME COLUMN `Revenues (FY 2022) ($mm)` TO Revenue;
ALTER TABLE latest_index
RENAME COLUMN `Operating_Income (FY 2022) ($mm)` TO Operating_Income;
ALTER TABLE latest_index
RENAME COLUMN `Shares_Outstanding (10-5-23) (mm)` TO Shares_Oustanding;
ALTER TABLE latest_index
RENAME COLUMN `Day_High_Price (10-5-23) ($)` TO Day_High;
ALTER TABLE latest_index
RENAME COLUMN `Day_Close_Price (10-5-23) ($)` TO Day_Close;
ALTER TABLE latest_index
RENAME COLUMN `Day_Low_Price (10-5-23) ($)` TO Day_Low;

# Checking the final table
select * from latest_index;

# Creaing new table to import the base stock price data (Base Date: Jan 3, 2023).

CREATE TABLE old_data (
  `Company Name` VARCHAR(5000),
  `Exchange:Ticker` TEXT,
  `Industry Classifications` TEXT,
  `Geographic Locations` TEXT,
  Day_Close_Base DOUBLE(15,2)
);

select*from old_data;


-- Add a new column to the latest_index table
ALTER TABLE latest_index
ADD COLUMN Day_Close_Base DOUBLE;

-- Update the values in the day_close_base column of latest_index table by joining with the old_data table
UPDATE latest_index AS l
JOIN old_data AS o ON l.`Exchange:Ticker` = o.`Exchange:Ticker`
SET l.day_close_base = o.day_close_base;

-- Checking the final table before cleaning
select*from latest_index;
-- Cleaning the table to delete all the null values.
DELETE FROM latest_index
WHERE Day_Close_Base IS NULL;
DELETE FROM latest_index
WHERE Day_Close_Base = 0;

-- Creating new table which will be used for calculation and selecting top 50 stocks by market captalization (weighting methodology).

CREATE TABLE index_calculation AS
SELECT *
FROM latest_index
ORDER BY market_cap DESC
LIMIT 50;

-- Checking the new table.
SELECT COUNT(*)
FROM index_calculation;

select*from index_calculation;

-- Adding New necessary columns for index Calculations. 
ALTER TABLE index_calculation
ADD COLUMN Weight_by_Market_Cap float;

ALTER TABLE index_calculation
ADD COLUMN Adjusted_Weight float;

SELECT*FROM index_calculation;

-- Calculating Total market cap and assigning it to a variable named "Total_market_cap".
SELECT @total_market_cap := SUM(market_cap) FROM index_calculation;

-- Filling the values of new columns created by formulaes.

UPDATE index_calculation
SET Weight_by_Market_Cap = market_cap / @total_market_cap;

-- UPDATE index_calculation
-- SET adjusted_weight = market_cap / @total_market_cap;

-- Set the limit of 20% to be the highest weight and no stock can have weight more than 20% in the index.
-- Counting the number of stocks having weight more than 20%.
SELECT COUNT(*) FROM index_calculation where weight_by_market_cap > 0.2;

-- Calculations and assigning them to variables
SELECT @weight_others := SUM(weight_by_market_cap) FROM index_calculation WHERE weight_by_market_cap < 0.2;
SELECT @weight_large := SUM(weight_by_market_cap) FROM index_calculation WHERE weight_by_market_cap > 0.2;
SELECT @weight_diff := 1-0.4;
select @weight_divisor := @weight_diff / @weight_others;

select SUM(Weight_by_market_cap) FROM index_calculation;
select SUM(Weight_by_market_cap) FROM index_calculation where weight_by_market_cap < 0.2;

-- Filling the values of adjusted weight column to calculate the adjusted weight derived with Weight Divisor.

UPDATE index_calculation
SET adjusted_weight = 0.2
WHERE weight_by_market_cap > 0.2;

UPDATE index_calculation
SET adjusted_weight = weight_by_market_cap * @weight_divisor
WHERE weight_by_market_cap < 0.2;

-- Checking the values of table to see if the adjusted weight total 100%.

select*from index_calculation;
select sum(adjusted_weight) from index_calculation where adjusted_weight < 0.2;
select sum(adjusted_weight) from index_calculation;

-- Creating new necessary columns for adjusted stock prices.

ALTER TABLE index_calculation
ADD COLUMN adjusted_day_close_base float;
ALTER TABLE index_calculation
ADD COLUMN adjusted_day_close_latest float;

-- Filling the values of new columns with appropriate formulaes.

update index_calculation
set adjusted_day_close_base = adjusted_weight * day_close_base;

update index_calculation
set adjusted_day_close_latest = adjusted_weight * day_close;

-- Calculation of Weight Stock Prices for base date (Jan 3, 2023) and calculation date (May 10, 2023) and assigning them variables.

select @Total_weighted_stock_price := sum(adjusted_day_close_latest) from index_calculation;
select @base_index_value := 1000;
select @Total_weighted_stock_price_base := sum(adjusted_day_close_base) from index_calculation;

-- Index Value Calculation.

SELECT @index_value := @Total_weighted_stock_price/@Total_weighted_stock_price_base * @base_index_value;
SELECT (@index_change := ((@index_value - @base_index_value) / @base_index_value) * 100) AS percentage_change;

################################
-- Creating new columns to add all the calculated values. All the calculated values will be added to the last row of sheet. 
-- And adding a row of Final Calculations to the table.

INSERT INTO index_calculation(Company_name) VALUES('Final Calculation');

ALTER TABLE index_calculation 
ADD COLUMN Index_Value float;
ALTER TABLE index_calculation 
ADD COLUMN Index_Change float;
ALTER TABLE index_calculation 
ADD COLUMN base_index_value INT;
ALTER TABLE index_calculation 
ADD COLUMN Total_weighted_stock_price float;
ALTER TABLE index_calculation 
ADD COLUMN Total_weighted_stock_price_base float;

UPDATE Index_Calculation
SET Index_Value = @index_value
WHERE Company_Name = 'Final Calculation';

UPDATE Index_Calculation
SET Index_Change = @Index_Change
WHERE Company_Name = 'Final Calculation';

UPDATE Index_Calculation
SET base_index_value = @base_index_value
WHERE Company_Name = 'Final Calculation';

UPDATE Index_Calculation
SET Total_weighted_stock_price = @Total_weighted_stock_price
WHERE Company_Name = 'Final Calculation';

UPDATE Index_Calculation
SET Total_weighted_stock_price_base = @Total_weighted_stock_price_base
WHERE Company_Name = 'Final Calculation';

SELECT * FROM Index_Calculation;

-- Changing the Sequence of Calculation Columns.

ALTER TABLE Index_Calculation
MODIFY COLUMN Total_weighted_stock_price float AFTER adjusted_day_close_latest,
MODIFY COLUMN Total_weighted_stock_price_base float AFTER Total_weighted_stock_price,
MODIFY COLUMN base_index_value float AFTER Total_weighted_stock_price_base,
MODIFY COLUMN Index_Value float AFTER base_index_value,
MODIFY COLUMN Index_Change float AFTER Index_Value;

ALTER TABLE Index_Calculation
RENAME COLUMN Index_Change TO Index_Change_Percentage;

-- Final Table with all the Calculation and Index Value

SELECT * FROM Index_Calculation;

-- -- -- END -- -- -- 