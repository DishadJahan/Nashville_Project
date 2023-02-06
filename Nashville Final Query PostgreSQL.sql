-- Table "nash_data" is created:

create table nash_data(
	Unique_ID int, Parcel_ID varchar, Land_Use varchar(50), Property_Address varchar, Sale_Date date,
	Sale_Price	int, Legal_Reference varchar, Sold_As_Vacant varchar, Owner_Name varchar,
	Owner_Address varchar, Acreage	float, Tax_District varchar, Land_Value int, Building_Value	int,
	Total_Value	int, Year_Built	int, Bedrooms int, Full_Bath int, Half_Bath int);


-- Used "IMPORT/EXPORT" function to "IMPORT the Excel data" to PostgreSQL Database.

=============================================================================================================================
-- Cleaning Data with SQL Queries.
=============================================================================================================================

--1. Standardize Date Format.

Select Sale_Date_Converted, CONVERT(Date,Sale_Date)
From nash_data


Update nash_data
SET Sale_Date = CONVERT(Date,Sale_Date)

-- If it doesn't Update properly

ALTER TABLE nash_data
Add Sale_Date_Converted Date;

Update nash_data
SET Sale_Date_Converted = CONVERT(Date,Sale_Date)

=============================================================================================================================

--2. Populate Property Address data.

select a.parcel_id, a.property_address, b.parcel_id, b.property_address,
	coalesce(a.property_address, b.property_address)
from nash_data a
join nash_data b
	on a.parcel_id = b.parcel_id
	and a.unique_id <> b.unique_id
where a.property_address is null;


-- "COALESCE" function in PostgreSQL = "ISNULL" function in MS SQL Server.
-- "ISNULL" is not supported in "PostgreSQL" database.
-- "COALESCE" function works perfectly in both "PostgreSQL" & "MS SQL Server databases".


update nash_data
	set property_address = coalesce(a.property_address, b.property_address)
from nash_data a
join nash_data b
	on a.parcel_id = b.parcel_id
	and a.unique_id <> b.unique_id
where a.property_address is null;

============================================================================================================================

--3. Breaking out Address into Individual Columns (Address, City, State).

Select 
 substring(property_address, 1, position(',' in property_address) - 1) as Address_1
,substring(property_address, (position(',' in property_address) + 1), char_length(property_address)) as Address_2
from nash_data;

Alter Table nash_data
Add prop_locality_address varchar;

Update nash_data
SET prop_locality_address = substring(property_address, 1, position(',' in property_address) - 1);

Alter Table nash_data
Add property_city varchar;

Update nash_data
Set property_city = substring(property_address, (position(',' in property_address) + 1), char_length(property_address));

Select * from nash_data;

-- "CHAR_LENGHT" function in PostgreSQL = "LEN" function in MS SQL Server.
-- Where as "POSITION" funtion is same for both the databases.

-- Breaking out Owner_Address into Individual Columns (Locality Address, City & State).

SELECT
   split_part(owner_address, ',', 1) as Address_1
  ,split_part(owner_address, ',', 2) as Address_2
  ,split_part(owner_address, ',', 3) as Address_3
from nash_data;

-- Creating 1st new column.

Alter Table nash_data
Add Owner_Locality_Address varchar;

Update nash_data
Set Owner_Locality_Address = split_part(owner_address, ',', 1);

-- Creating 2nd new column.

Alter Table nash_data
Add Owner_City varchar;

Update nash_data
Set Owner_City = split_part(owner_address, ',', 2);

-- Creating 3rd new column.

Alter Table nash_data
Add Owner_State varchar;

Update nash_data
Set Owner_State = split_part(owner_address, ',', 3);


Select * from nash_data;

-- "SPLIT_PART" function in PostgreSQL = "PARSENAME" function in MS SQL Server.
	
============================================================================================================================

--3. Change Y and N to Yes and No in "Sold as Vacant" field.

SELECT sold_as_vacant
From nash_data;

Select distinct (sold_as_vacant), count(sold_as_vacant) as count
from nash_data
group by sold_as_vacant
order by 2 desc;

Select sold_as_vacant,
	Case When sold_as_vacant = 'Y' Then 'Yes'
		 When sold_as_vacant = 'N' Then 'No'
		 Else sold_as_vacant
		 End as New_SoldAsVacant
From nash_data;

-- Updating the "sold_as_vacant" column.

Update nash_data
Set sold_as_vacant = Case When sold_as_vacant = 'Y' Then 'Yes'
		 				  When sold_as_vacant = 'N' Then 'No'
		 				  Else sold_as_vacant
		 				  End;


============================================================================================================================

--4. Remove Duplicates

Select *
From nash_data;

-- I dentifying the Duplicate items/entries/data using "CTE" and "WINDOWS FUNCTION".

With dup_data as (Select *,
				  Row_Number() Over(Partition By parcel_id, property_address, sale_date, owner_address, legal_reference
					 				order by unique_id) as row_num
				  From nash_data)
Select *
From dup_data
Where row_num > 1;

-- Deleting the Duplicate Entries/Data using "DELETE" function.

With dup_data as (Select *,
				  Row_Number() Over(Partition By parcel_id, property_address, sale_date, owner_address, legal_reference
					 				order by unique_id) as row_num
				  From nash_data)
Delete
From dup_data
Where row_num > 1;


Select *
From nash_data;

============================================================================================================================

--5. Deleting Unused Columns.

Alter Table nash_data
Drop Column property_address, owner_address, tax_district;


Select *
From nash_data;


============================================================================================================================
























