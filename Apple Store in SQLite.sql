/*JOINING TABLES*/

CREATE TABLE appleStore_description_combined AS

SELECT * 
FROM appleStore_description1

UNION ALL

SELECT * 
FROM appleStore_description2

UNION ALL

SELECT * 
FROM appleStore_description3

UNION ALL

SELECT * 
FROM appleStore_description4


/*DATA VALIDATION*/

--Checking the number of unique apps in both tables.
--Since both queries are the same, there are no missing data between the two
SELECT COUNT(DISTINCT id) AS UniqueAppIDs
FROM AppleStore

SELECT COUNT(DISTINCT id) AS UniqueAppIDs
FROM appleStore_description_combined

--Checking for missing values in key fields 
--Since both are zero, there are no missing values
SELECT COUNT(*) AS MissingValues
FrOM AppleStore
WHERe track_name IS NULL
OR user_rating IS NULL
or prime_genre IS NULL

SELECT COUNT(*) AS MissingValues
FROM appleStore_description_combined
WHERE app_desc IS NULL

--Finding out the number of apps per genreAppleStore
SELECT prime_genre, COUNT(*) AS NumberOfApps
FROM AppleStore
GROUP BY prime_genre
order by COUNT(*) DESC

--Overview of apps ratingAppleStore
SELECT MIN(user_rating) AS MinRating,
	MAX(user_rating) AS MaxRating,
    AVG(user_rating) AS AvgRating
FROM AppleStore


/*DATA ANALYSIS*/

--Determining whether paid apps have higher ratings than free apps 
SELECT 
CASE WHEN price > 0 THEN 'paid'
	ELSE 'Free'
    END AS AppType,
    AVG(user_rating) as AvgRating
FROM AppleStore
GROUP BY AppType
ORDER BY AvgRating DESC

--Checking if apps with more languages have higher ratings 
SELECT
CASE WHEN lang_num <10 THEN '<10 languages'
	WHEN lang_num BETWEEN 10 AND 30 THEN '10-30 languages'
    ELSE '30+ languages'
    END AS lang_group,
    AVG(user_rating) as AvgRating
FROM AppleStore
GROUP BY lang_group
ORDER BY AvgRating DESC

--Checking genres with low rating 
SELECT prime_genre,
	AVG(user_rating) as AvgRating
FROM AppleStore
GROUP BY prime_genre
ORDER BY AvgRating
LIMIT 10

--Checking if there is correlation between the length of app desc and user rating 
SELECT
CASE WHEN LENGTH(adc.app_desc) <500 THEN 'short'
	WHEN LENGTH(adc.app_desc) BETWEEN 500 AND 1000 THEN 'medium'
    ELSE 'Long'
    END AS desc_length,
    AVG(a.user_rating) as AvgRating
FROM AppleStore AS a
JOIN appleStore_description_combined as adc
ON a.id = adc.id
GROUP BY desc_length
ORDER BY AvgRating DESC

--Checking the top-rated apps for each genre 
WITH cte AS (
  SELECT prime_genre,
	track_name,
    user_rating,
  	RANK() OVER(PARTITION BY prime_genre ORDER BY user_rating DESC, rating_count_tot DESC) as ranking
  from AppleStore
)

SELECT prime_genre,
	track_name,
    user_rating
 FROM cte
 WHERE ranking = 1