-- Question Set 1 - Easy:

-- Q1: Who is the senior most employee based on job title?

SELECT *
FROM EMPLOYEE
ORDER BY LEVELS DESC
LIMIT 1;

-- Q2: Which countries have the most Invoices?

SELECT COUNT(*) AS TOTAL_INVOICES,
	BILLING_COUNTRY
FROM INVOICE
GROUP BY BILLING_COUNTRY
ORDER BY TOTAL_INVOICES DESC;

-- Q3: What are top 3 values of total invoice?

SELECT TOTAL
FROM INVOICE
ORDER BY TOTAL DESC
LIMIT 3;

-- Q4: Which city has the best customers?
 -- We would like to throw a promotional Music Festival in the city we made the most money.
 -- Write a query that returns one city that has the highest sum of invoice totals.
 -- Return both the city name & sum of all invoice totals.

SELECT BILLING_CITY,
	SUM(TOTAL) AS INVOICE_TOTAL
FROM INVOICE
GROUP BY BILLING_CITY
ORDER BY INVOICE_TOTAL DESC
LIMIT 1;

-- Q5: Who is the best customer?
 -- The customer who has spent the most money will be declared the best customer.
 -- Write a query that returns the person who has spent the most money

SELECT CUSTOMER_ID,
	FIRST_NAME,
	LAST_NAME
FROM CUSTOMER
WHERE CUSTOMER_ID in
		(SELECT CUSTOMER_ID
			FROM INVOICE
			GROUP BY CUSTOMER_ID
			ORDER BY SUM(TOTAL) DESC
			LIMIT 1) ;

-- OR Method 2:

SELECT C.CUSTOMER_ID,
	C.FIRST_NAME,
	C.LAST_NAME,
	SUM(I.TOTAL) AS TOTAL
FROM CUSTOMER C
JOIN INVOICE I ON C.CUSTOMER_ID = I.CUSTOMER_ID
GROUP BY C.CUSTOMER_ID
ORDER BY TOTAL DESC
LIMIT 1;

-- Question Set 2- Moderate:

 -- Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
 -- Return your list ordered alphabetically by email starting with A

SELECT DISTINCT CUSTOMER.EMAIL,
	CUSTOMER.FIRST_NAME,
	CUSTOMER.LAST_NAME
FROM CUSTOMER
JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
WHERE TRACK_ID in
		(SELECT TRACK_ID
			FROM TRACK
			WHERE GENRE_ID =
					(SELECT GENRE_ID
						FROM GENRE
						WHERE NAME like 'Rock'))
ORDER BY EMAIL; -- asc: starting from 'A'

-- OR Method 2:

SELECT DISTINCT CUSTOMER.EMAIL,
	CUSTOMER.FIRST_NAME,
	CUSTOMER.LAST_NAME
FROM CUSTOMER
JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
WHERE TRACK_ID in
		(SELECT TRACK.TRACK_ID
			FROM TRACK
			JOIN GENRE ON TRACK.GENRE_ID = GENRE.GENRE_ID
			WHERE GENRE.NAME like 'Rock')
ORDER BY EMAIL; -- asc: starting from 'A'

-- Q2: Let's invite the artists who have written the most rock music in our dataset. 
 -- Write a query that returns the Artist name and total track count of the top 10 rock bands 
 
SELECT ARTIST.ARTIST_ID, 
	ARTIST.NAME, 
	COUNT(ARTIST.ARTIST_ID) AS NUMBER_OF_SONGS
FROM ARTIST
JOIN ALBUM ON ALBUM.ARTIST_ID = ARTIST.ARTIST_ID
JOIN TRACK ON TRACK.ALBUM_ID = ALBUM.ALBUM_ID
JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID 
WHERE GENRE.NAME like 'Rock'
GROUP BY ARTIST.ARTIST_ID
ORDER BY NUMBER_OF_SONGS DESC
LIMIT 10;

-- Q3: Return all the track names that have a song length longer than the average song length.
 -- Return the Name and Milliseconds for each track.
 -- Order by the song length with the longest songs listed first

SELECT NAME,
	MILLISECONDS
FROM TRACK
WHERE MILLISECONDS >
		(SELECT AVG(MILLISECONDS)
			FROM TRACK)
GROUP BY TRACK_ID
ORDER BY MILLISECONDS DESC;

-- OR Method 2:

SELECT NAME,
	MILLISECONDS
FROM TRACK
JOIN
	(SELECT AVG(MILLISECONDS) AS AVG_MILLISECONDS
		FROM TRACK) AS AVG_TRACK ON MILLISECONDS > AVG_TRACK.AVG_MILLISECONDS
ORDER BY TRACK.MILLISECONDS DESC;

-- Question Set 3- Advance:

 -- Q1: Find how much amount spent by each customer on artists?
 -- Write a query to return customer name, artist name and total spent
 
 --> invoice( total_cost=Quantity * unit_prize)
 
 -- to get the artist id, name and total sales of top artist.
WITH TOP_SELLING_ARTIST AS
	(SELECT ARTIST.ARTIST_ID,
			ARTIST.NAME,
			SUM(INVOICE_LINE.UNIT_PRICE * INVOICE_LINE.QUANTITY) AS TOTAL_SPENT
		FROM ARTIST
		JOIN ALBUM ON ARTIST.ARTIST_ID = ALBUM.ARTIST_ID
		JOIN TRACK ON ALBUM.ALBUM_ID = TRACK.ALBUM_ID
		JOIN INVOICE_LINE ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
		GROUP BY 1 -- 1: artist.artist_id

		ORDER BY 3 DESC -- 3: SUM(invoice_line.unit_price * invoice_line.quantity) as total_spent

		LIMIT 1) -- to get customer details who spent most in top_artist from above CTE

SELECT CX.CUSTOMER_ID,
	CX.FIRST_NAME,
	CX.LAST_NAME,
	TSA.NAME,
	SUM(IL.UNIT_PRICE * IL.QUANTITY) AS CX_TOTAL_SPENT_ON_TOP_ARTIST
FROM CUSTOMER CX   --  to join customer and cte on artist_id we need tables = customer,invoice,invoice_line, track,album,CTE table
JOIN INVOICE I ON CX.CUSTOMER_ID = I.CUSTOMER_ID
JOIN INVOICE_LINE IL ON I.INVOICE_ID = IL.INVOICE_ID
JOIN TRACK TR ON IL.TRACK_ID = TR.TRACK_ID
JOIN ALBUM AL ON TR.ALBUM_ID = AL.ALBUM_ID
JOIN TOP_SELLING_ARTIST TSA ON AL.ARTIST_ID = TSA.ARTIST_ID
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- Q2: We want to find out the most popular music Genre for each country.
 -- We determine the most popular genre as the genre with the highest amount of purchases.
 -- Write a query that returns each country along with the top Genre.
 -- For countries where the maximum number of purchases is shared return all Genres
 
 --> 	genre_id, genre_name, purchase (highest count(quantity))=> top genre, | each country
 
WITH POPULAR_GENRE AS
	(SELECT COUNT(IL.QUANTITY) AS PURCHASE,
			CX.COUNTRY,
			GR.GENRE_ID,
			GR.NAME,
			ROW_NUMBER() OVER (PARTITION BY CX.COUNTRY ORDER BY COUNT(IL.QUANTITY) DESC) AS rownum
		FROM GENRE GR
		JOIN TRACK TR ON GR.GENRE_ID = TR.GENRE_ID
		JOIN INVOICE_LINE IL ON TR.TRACK_ID = IL.TRACK_ID
		JOIN INVOICE I ON IL.INVOICE_ID = I.INVOICE_ID
		JOIN CUSTOMER CX ON I.CUSTOMER_ID = CX.CUSTOMER_ID
		GROUP BY 2,3,
			4
		ORDER BY 2 ASC, 1 DESC)
SELECT *
FROM POPULAR_GENRE
WHERE rownum <= 1;

-- OR Method 2: Recursive CTE:

 WITH RECURSIVE POPULAR_GENRE AS
	(SELECT COUNT(IL.QUANTITY) AS PURCHASE,
			CX.COUNTRY,
			GR.GENRE_ID,
			GR.NAME
		FROM GENRE GR
		JOIN TRACK TR ON GR.GENRE_ID = TR.GENRE_ID
		JOIN INVOICE_LINE IL ON TR.TRACK_ID = IL.TRACK_ID
		JOIN INVOICE I ON IL.INVOICE_ID = I.INVOICE_ID
		JOIN CUSTOMER CX ON I.CUSTOMER_ID = CX.CUSTOMER_ID
		GROUP BY 2,3,4
		ORDER BY 2 ASC, 1 DESC),
	MAX_GENRE_PER_COUNTRY AS
	(SELECT COUNTRY,
			MAX(PURCHASE) AS MAXIMUM_PER_COUNTRY
		FROM POPULAR_GENRE
		GROUP BY 1
		ORDER BY 1)
SELECT GENRE_ID,
	NAME,
	GC.COUNTRY,
	MAXIMUM_PER_COUNTRY,
	PURCHASE
FROM MAX_GENRE_PER_COUNTRY GC
JOIN POPULAR_GENRE PG ON GC.COUNTRY = PG.COUNTRY
WHERE PURCHASE = MAXIMUM_PER_COUNTRY;

-- Q3: Write a query that determines the customer that has spent the most on music for each country.
 -- Write a query that returns the country along with the top customer and how much they spent.
 -- For countries where the top amount spent is shared, provide all customers who spent this amount
 
 WITH CUSTOMER_COUNTRY AS
	(SELECT CX.CUSTOMER_ID,
			CX.FIRST_NAME,
			CX.LAST_NAME,
			CX.COUNTRY,
			SUM(I.TOTAL) AS TOTAL,
			ROW_NUMBER() OVER(PARTITION BY CX.COUNTRY ORDER BY MAX(I.TOTAL)) AS rownum
		FROM CUSTOMER CX
		JOIN INVOICE I ON CX.CUSTOMER_ID = I.CUSTOMER_ID
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC, 6 DESC)
SELECT *
FROM CUSTOMER_COUNTRY
WHERE rownum <= 1;

-- OR Method 2: Recursive CTE

 WITH RECURSIVE CUSTOMER_COUNTRY AS
	(SELECT CX.CUSTOMER_ID,
			CX.FIRST_NAME,
			CX.LAST_NAME,
			CX.COUNTRY,
			SUM(I.TOTAL) AS TOTAL
		FROM CUSTOMER CX
		JOIN INVOICE I ON CX.CUSTOMER_ID = I.CUSTOMER_ID
		GROUP BY 1,2,3,4
		ORDER BY 1,5 DESC),
	COUNTRY_WISE_MAX AS
	(SELECT COUNTRY,
			MAX(TOTAL) AS MAX_SPENDING
		FROM CUSTOMER_COUNTRY
		GROUP BY COUNTRY)
SELECT CC.CUSTOMER_ID,
	CC.FIRST_NAME,
	CC.LAST_NAME,
	CC.COUNTRY,
	MAX_SPENDING,
	TOTAL
FROM COUNTRY_WISE_MAX C
JOIN CUSTOMER_COUNTRY CC ON C.COUNTRY = CC.COUNTRY
WHERE MAX_SPENDING = TOTAL
ORDER BY 4 ;