-- Table View.
Select * from nash_data;

=====================================================================================================================
-- Cleaning Data in SQL Queries
=====================================================================================================================



=====================================================================================================================
--1. Standardize Date Format
=====================================================================================================================

Select Sale_Date_Converted, CONVERT(Date,Sale_Date)
From nash_data


Update nash_data
SET Sale_Date = CONVERT(Date,Sale_Date)

-- If it doesn't Update properly

ALTER TABLE nash_data
Add Sale_Date_Converted Date;

Update nash_data
SET Sale_Date_Converted = CONVERT(Date,Sale_Date)



=====================================================================================================================
--2. Populate Property Address data.
=====================================================================================================================

Select a.Parcel_ID, a.Property_Address, b.Parcel_ID, b.Property_Address, 
ISNULL(a.PropertyAddress,b.PropertyAddress)
from nash_data a
join nash_data b
on a.Parcel_ID = b.Parcel_ID
and a.Unique_ID <> b.Unique_ID;
where a.Property_Address is null


-- "COALESCE" function in PostgreSQL = "ISNULL" function in MS SQL Server.
-- "ISNULL" is not supported in "PostgreSQL" database.
-- "COALESCE" function works perfectly in both "PostgreSQL" & "MS SQL Server databases".


Update a
Set Property_Address = Isnull(a.Property_Address, b.Property_Address)
from nash_data a
join nash_data b
on a.Parcel_ID = b.Parcel_ID
and a.Unique_ID <> b.Unique_ID
where a.Property_Address is null;

select * 
from nash_data
order by Parcel_ID;



=====================================================================================================================
--3. Breaking out Address into Individual Columns (Address, City, State).
=====================================================================================================================

select * 
from nash_data;

-- "CHAR_LENGHT" function in PostgreSQL = "LEN" function in MS SQL Server.
-- Where as "POSITION" funtion is same for both the databases.

select 
substring(Property_Address, 1, Charindex(',', Property_Address) -1) as Address_1,
substring(Property_Address, (Charindex(',', Property_Address) +1), Len(Property_Address)) as Address_2
from nash_data;

-- Now creating 2 new columns to add the updated data.

-- Altering & updating the 1st new column:

ALTER TABLE nash_data
Add Property_Locality_Address nvarchar(255);

Update nash_data
SET Property_Locality_Address = substring(Property_Address, 1, Charindex(',', Property_Address) -1);

-- Now altering & updating the 2nd new column:

ALTER TABLE nash_data
Add Property_City nvarchar(255);

Update nash_data
SET Property_City = substring(Property_Address, (Charindex(',', Property_Address) +1), Len(Property_Address));

-- Breaking out Owner_Address into Individual Columns (Locality Address, City & State).

Select Owner_Address
From nash_data;


Select
   Parsename(Replace(Owner_Address, ',', '.'), 3) as Owner_Locatity
  ,Parsename(Replace(Owner_Address, ',', '.'), 2) as Owner_City
  ,Parsename(Replace(Owner_Address, ',', '.'), 1) as Owner_State
from nash_data;

-- Creating 1st new column.

Alter Table nash_data
Add Owner_Locatity_Address  nvarchar(255);

Update nash_data
Set Owner_Locatity_Address = Parsename(Replace(Owner_Address, ',', '.'), 3);

-- Creating 2nd new column.

Alter Table nash_data
Add Owner_City nvarchar(255);

Update nash_data
Set Owner_City = Parsename(Replace(Owner_Address, ',', '.'), 2);

-- Creating 3rd new column.

Alter Table nash_data
Add Owner_State nvarchar(255);

Update nash_data
Set Owner_State = Parsename(Replace(Owner_Address, ',', '.'), 1);


Select *
From nash_data;

-- "SPLIT_PART" function in PostgreSQL = "PARSENAME" function in MS SQL Server.

=====================================================================================================================
--3. Change Y and N to Yes and No in "Sold as Vacant" field.
=====================================================================================================================

Select distinct(Sold_As_Vacant), count(Sold_As_Vacant) as count
From nash_data
group by Sold_As_Vacant
order by count desc;


Select Sold_As_Vacant, 
	case 
	when Sold_As_Vacant = 'Y' Then 'Yes'
	when Sold_As_Vacant = 'N' Then 'No'
	Else Sold_As_Vacant
	End as New_SoldAsVacant
From nash_data;

-- Updating "Sold_As_Vacant" with the new Format.

Update nash_data
Set Sold_As_Vacant = case when Sold_As_Vacant = 'Y' Then 'Yes'
						  when Sold_As_Vacant = 'N' Then 'No'
						  Else Sold_As_Vacant
						  End;


Select Sold_As_Vacant
From nash_data;


=====================================================================================================================
--4. Remove Duplicates
=====================================================================================================================


Select *
From nash_data;

Select  distinct Parcel_ID
From nash_data
group by Parcel_ID;



-- I dentifying the Duplicate items/entries/data using "CTE" and "WINDOWS FUNCTION".

With dup_data as (Select *,
				   Row_Number() Over(Partition by Parcel_ID, Property_Address, Sale_Date, Sale_Price, Legal_Reference
									 Order by Unique_ID) as row_num
				 From nash_data)
Select *
From dup_data
Where row_num > 1
Order by Property_Address;



-- Deleting the Duplicate Entries/Data using "DELETE" function.

With dup_data as (Select *,
				   Row_Number() Over(Partition by Parcel_ID, Property_Address, Sale_Date, Sale_Price, Legal_Reference
									 Order by Unique_ID) as row_num
				 From nash_data)
Delete
From dup_data
Where row_num > 1;

Select *
From nash_data;


=====================================================================================================================
--5. Deleting Unused Columns.
=====================================================================================================================

Alter Table nash_data
Drop Column Property_Address, Owner_Address, Tax_District;

Select *
From nash_data;


=====================================================================================================================
--6. Data Extraction and Loading for further Analysis.
=====================================================================================================================

/*Created a separate VIEW with "VIEW" function to extract and load it to Excel for creating Dashboard for 
Visualization and further analysis and submit report to management and stakeholders for review and response*/

Create View Clean_Data as 
Select Unique_ID, Parcel_ID, Property_Locality_Address, Property_City, Coalesce(Owner_State, ' TN') as Owner_State, Land_Use, Sale_Date, Sale_Price, 
	   Sold_As_Vacant, 
	   coalesce(Land_Value, 0) as Land_Value, 
	   coalesce(Building_Value, 0) as Building_Value, 
	   coalesce(Total_Value, 0) as Total_Property_Value, 
	   coalesce(Bedrooms, 0) as Bedrooms, 
	   coalesce(Full_Bath, 0) as Full_Bath, 
	   coalesce(Half_Bath, 0) as Half_Bath
From nash_data;


=====================================================================================================================

