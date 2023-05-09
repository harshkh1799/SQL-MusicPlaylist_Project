--EASY

--Q1: Who is senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

--Q2: Which countries have the most invoices?
SELECT billing_country as Country, COUNT(billing_country) AS c
FROM invoice
GROUP BY Country
ORDER BY c DESC
LIMIT 5;

--Q3: What are the top 3 values of total invoice?
SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

/*Q4: Which city has best customers? We would like to throw a promotional Music festival in the city we made
the most money. Write a query that returns one city that has the highest sum of invoice totals.
Return both the city name & sum of all invoice totals*/
SELECT billing_city, sum(total) as sum_invoice
FROM invoice
GROUP BY billing_city
ORDER BY sum_invoice DESC
LIMIT 1;

--Q5: Who is the best customer with highest spent money? 
SELECT a.customer_id, a.first_name, a.last_name, SUM(b.total) as s 
FROM customer AS a
INNER JOIN invoice AS b
ON a.customer_id=b.customer_id
GROUP BY a.customer_id
ORDER BY s DESC
LIMIT 1;





--MODERATE





--Q1: Write query to return the email, first name, last name & genre of all rock music listeners.
--Return list ordered alphabetically by email starting with A.

select first_name, last_name, email from customer where customer_id IN(
	select customer_id from invoice where invoice_id IN(
		select invoice_id from invoice_line where track_id IN(
			select track_id from track where genre_id IN(
				select genre_id from genre where name IN ('Rock')))))
				order by email;
--Another way: Not optimal because of too many joins
SELECT DISTINCT first_name AS FirstName, last_name AS LastName, email AS Email, genre.name AS Name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE ('Rock')
ORDER BY Email;

--Guided way:
SELECT DISTINCT first_name, last_name, email 
FROM customer 
JOIN invoice ON customer.customer_id=invoice.customer_id
JOIN invoice_line ON invoice.invoice_id=invoice_line.invoice_id
WHERE track_id IN(
SELECT a.track_id 
FROM track AS a
JOIN genre AS b
ON a.genre_id = b.genre_id
WHERE b.name='Rock')
ORDER BY email;

/* Q2: LETS INVITE ARTIST WHO HAVE WRITTEN MOST ROCK MUSIC IN OUR DATASET. Write a query that return artist name
and total track count of top 10 rock bands*/
--WRONG-- Probably reason: Grouping is not done right
SELECT artist.artist_id, artist.name, count(artist.artist_id) as num FROM artist
JOIN album ON artist.artist_id=album.artist_id
WHERE album_id IN(
SELECT track.album_id FROM track
JOIN genre ON track.genre_id=genre.genre_id
WHERE genre.name LIKE 'Rock')
GROUP BY artist.artist_id
ORDER BY num desc
LIMIT 10;
--Another way
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) as num 
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY num DESC
LIMIT 10;

/* Q3: Return all track names that have a song length longer than the average song length. Retun the name and milli-
seconds for each track. Order by the song length with the longest songs listed first */
SELECT name, milliseconds, media_type_id
FROM track 
WHERE milliseconds >
( SELECT AVG(milliseconds) AS avg_track_length
 FROM track)
 ORDER BY milliseconds DESC;






-- ADVANCE






/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name
and total spend */
WITH best_selling_artist AS (
		SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price * invoice_line.quantity) as total_sales
		FROM invoice_line
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN album ON album.album_id = track.album_id
		JOIN artist ON artist.artist_id = album.artist_id
		GROUP BY 1
		ORDER BY 3 DESC
		LIMIT 1
)
SELECT customer.customer_id, customer.first_name, customer.last_name, bsa.artist_name, 
SUM(invoice_line.unit_price * invoice_line.quantity) AS total_spent
FROM invoice
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN best_selling_artist as bsa ON bsa.artist_id = album.artist_id
GROUP BY 1,4
ORDER BY total_spent DESC;


/* Q2: We want to find out most popular music genre for each country. We determine most popular genre as the genre with the highest amount of purchases
Write a query that returns each country along with the top genre, For countries where the maximum number of purchases is shared return all genres.*/
WITH popular_genre AS(
		SELECT COUNT(invoice_line.quantity) as purchases, customer.country, genre.genre_id, genre.name,
		ROW_NUMBER() OVER ( PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS rownum
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE rownum<=1	


/* Q5: Write a query that determines the customer that has spent the most on music for each country. Write query taht returns the country along with
top customer and how much they spent. For countries where the top spent is shared, provide all customers who spent this amount*/

WITH customer_for_country AS (
		SELECT c.customer_id, c.first_name, c.last_name,i.billing_country, SUM(i.total) as total_spending,
		ROW_NUMBER() OVER ( PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS RowNum
		FROM invoice AS i
		JOIN customer AS c ON c.customer_id = i.customer_id
		GROUP BY 1,4
		ORDER BY 4 ASC, 5 DESC
	)
SELECT * FROM customer_for_country WHERE RowNum <= 1