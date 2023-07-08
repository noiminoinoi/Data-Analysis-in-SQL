
-- CLEANING DATA

SELECT *
FROM PorfolioProject.dbo.NashvilleHousing

-- Standardizing Date Format

ALTER TABLE NashvilleHousing
ADD sale_date DATE;

Update PorfolioProject.dbo.NashvilleHousing
SET sale_date = CONVERT(DATE,SaleDate)

SELECT SaleDate, sale_date
FROM PorfolioProject.dbo.NashvilleHousing

-- Populating Property Address

SELECT original.ParcelID, original.PropertyAddress, altered.ParcelID, altered.PropertyAddress, ISNULL(original.PropertyAddress,altered.PropertyAddress)
FROM PorfolioProject.dbo.NashvilleHousing original
JOIN PorfolioProject.dbo.NashvilleHousing altered
	ON original.ParcelID = altered.ParcelID
	AND original.[UniqueID ] <> altered.[UniqueID ]
	WHERE original.PropertyAddress IS NULL

UPDATE original
SET PropertyAddress = ISNULL(original.PropertyAddress,altered.PropertyAddress)
FROM PorfolioProject.dbo.NashvilleHousing original
JOIN PorfolioProject.dbo.NashvilleHousing altered
	ON original.ParcelID = altered.ParcelID
	AND original.[UniqueID ] <> altered.[UniqueID ]
	WHERE original.PropertyAddress IS NULL

SELECT *
FROM PorfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

-- Breaking out Property Address into Individual Columns (Address, City)
SELECT PropertyAddress, 
SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) - 1) as SplitAdress,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM PorfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255),
	PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) - 1), 
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress))

SELECT PropertyAddress, SplitAddress, City
FROM PorfolioProject.dbo.NashvilleHousing

-- Breaking out Owner Address into Individual Columns (Address, City)
SELECT OwnerAddress, 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PorfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255),
OwnerSplitCity nvarchar(255),
OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PorfolioProject.dbo.NashvilleHousing

-- Normalizing Data. Changing Y and N to Yes and No in Sold as Vacant Column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PorfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PorfolioProject.dbo.NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PorfolioProject.dbo.NashvilleHousing

-- Removing Duplicates

Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) row_num
FROM PorfolioProject.dbo.NashvilleHousing


WITH RownumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) row_num
FROM PorfolioProject.dbo.NashvilleHousing
) 
DELETE
FROM RownumCTE
WHERE row_num > 1

--Deleting unused column

ALTER TABLE PorfolioProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

SELECT *
FROM PorfolioProject.dbo.NashvilleHousing

ALTER TABLE PorfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate