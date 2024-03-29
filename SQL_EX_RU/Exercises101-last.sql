﻿/* 101
The Printer table is sorted by the code field in ascending order.
The ordered rows form groups: the first group starts with the first row, each row having color=’n’ begins a new group, the groups of rows don’t overlap.
For each group, determine the maximum value of the model field (max_model), the number of unique printer types (distinct_types_cou), and the average price (avg_price).
For all table rows, display code, model, color, type, price, max_model, distinct_types_cou, avg_price. 
*/
WITH grouped AS (
SELECT code, model, color, type, price, CASE WHEN MAX(CASE WHEN p.color = 'n' THEN p.code END) OVER(ORDER BY p.code) IS NULL THEN 0 ELSE MAX(CASE WHEN p.color = 'n' THEN p.code END) OVER(ORDER BY p.code) END AS grp FROM Printer p
)
select code, model, color, type, price, MAX(model) OVER(PARTITION BY G.grp) AS max_model, d.dist_type,
	AVG(price) OVER(PARTITION BY G.grp) AS avg_price FROM grouped G
	JOIN ( SELECT g2.grp, COUNT(distinct g2.type) as dist_type FROM grouped g2 GROUP BY g2.grp) AS d ON G.grp = d.grp
/* 102
Find the names of different passengers who travelled between two towns only (one way or back and forth). 
*/
WITH trip_swapped AS
(
	SELECT trip_no, id_comp, plane, 
	CASE WHEN town_from > town_to THEN town_to ELSE town_from END as s_town_from, 
	CASE WHEN town_from > town_to THEN town_from ELSE town_to END AS s_town_to, 
	town_from, town_to FROM Trip
)
SELECT  p.name FROM Passenger p JOIN Pass_in_trip pit ON p.ID_psg = pit.id_psg
JOIN trip_swapped AS t ON pit.trip_no = t.trip_no
WHERE NOT EXISTS
(
	SELECT NULL FROM Pass_in_trip pit2 JOIN trip_swapped t2 ON pit2.trip_no = t2.trip_no
	WHERE 
		pit2.id_psg = pit.id_psg AND
		pit2.trip_no <> pit.trip_no AND
		(t.s_town_from <> t2.s_town_from OR t.s_town_to <> t2.s_town_to)
)
GROUP BY p.id_psg, p.name
/* 103
Find out the three smallest and three greatest trip numbers. Output them in a single row with six columns, ordered from the least trip number to the greatest one.
Note: it is assumed the Trip table contains 6 or more rows. 
*/
with cte as
(
Select trip_no, row_number() over(order by trip_no asc) as rn_asc, row_number() over(order by trip_no desc) as rn_desc
from trip),
mins_n_maxs as
(
 select trip_no, row_number() over(order by trip_no asc) as rn from cte where rn_asc <= 3 or rn_desc <=3
)
select * from mins_n_maxs
PIVOT
(
 MIN(trip_no) FOR rn IN ([1], [2], [3], [4], [5], [6])
) as x;
/* 104

For each cruiser class whose quantity of guns is known, number its guns sequentially beginning with 1.
Output: class name, gun ordinal number in 'bc-N' style. 
*/
with nums1 as (select 1 as n from (values(1), (1)) as c(n)),
nums2 as (select 1 as n from nums1 n1 cross join nums1 n2),
nums3 as (select 1 as n from nums2 n1 cross join nums2 n2),
rn as (select row_number() over(order by (select null)) as num
from nums3)

select class, 'bc-'+cast(rn.num as varchar) from classes join rn on numGuns >= rn.num
where type ='bc'
/* 105
Statisticians Alice, Betty, Carol and Diana are numbering rows in the Product table.
Initially, all of them have sorted the table rows in ascending order by the names of the makers.
Alice assigns a new number to each row, sorting the rows belonging to the same maker by model in ascending order.
The other three statisticians assign identical numbers to all rows having the same maker.
Betty assigns the numbers starting with one, increasing the number by 1 for each next maker.
Carol gives a maker the same number the row with this maker's first model receives from Alice.
Diana assigns a maker the same number the row with this maker's last model receives from Alice.
Output: maker, model, row numbers assigned by Alice, Betty, Carol, and Diana respectively. 
*/
SELECT maker, model,
ROW_NUMBER() OVER(ORDER BY maker, model) AS [Alice],
DENSE_RANK() OVER(ORDER BY maker) AS [Betty],
RANK() OVER(ORDER BY maker) AS [Carol],
COUNT(*) OVER (ORDER BY maker RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS [Diana]
FROM Product p1


/* 106
Let v1, v2, v3, v4, ... be a sequence of real numbers corresponding to paint amounts b_vol, sorted by b_datetime, b_q_id, and b_v_id in ascending order.
Find the transformed sequence P1=v1, P2=v1/v2, P3=v1/v2*v3, P4=v1/v2*v3/v4, ..., where each subsequent member is obtained from the preceding one by either multiplication by vi (for an odd i) or division by vi (for an even i).
Output the result as b_datetime, b_q_id, b_v_id, b_vol, Pi, with Pi being the member of the sequence corresponding to the record number i. Display Pi with eight decimal places.
*/

/* 107
Find the company, trip number, and trip date for the fifth passenger from among those who have departed from Rostov in April 2003.
Note. For this exercise it is assumed two flights can’t depart from Rostov simultaneously. 
*/
Select c.name, t.trip_no, pit.date from company c inner join trip t on c.id_comp = t.id_comp left join pass_in_trip pit on t.trip_no = pit.trip_no
where pit.date between '20030401' and '20030430'
and t.town_from = 'Rostov'
order by pit.date asc, t.time_out
offset 4 rows fetch next 1 row only

/* 108
The restoration of the exhibits of the Triangles department of the PFAS museum has been carried out according to the performance specification. For each record in the utb table, the painters restored the paint on the side of every geometric figure, provided this side had a length equal to b_vol.
Get all triangles having the paint on all their sides restored, except for equilateral, isosceles, and obtuse ones.
For each triangle (yet without duplicates), display three values X, Y, Z, where X is the length of the short, Y – of the medium, and Z – of the long triangle side.
*/

/* 109
Display:
1. The names of all squares that are black or white.
2. The total number of white squares.
3. The total number of black squares.
*/
WITH squares AS (
SELECT q.Q_NAME, SUM(b.B_VOL) AS all_sum_white, COUNT(CASE WHEN b.B_Q_ID IS NULL THEN 1 END) AS all_black FROM utQ q LEFT JOIN utB b ON q.Q_ID = b.B_Q_ID
GROUP BY q.Q_ID, q.Q_NAME
)
SELECT s.Q_NAME, COUNT(s.all_sum_white) OVER(), SUM(s.all_black) OVER() FROM squares s 
WHERE s.all_sum_white = 765 OR s.all_sum_white IS NULL 
/* 110
Find out the names of different passengers who ever travelled on a flight that took off on Saturday and landed on Sunday.
*/
select p.name from trip t inner join pass_in_trip pit on pit.trip_no = t.trip_no inner join passenger p on p.id_psg = pit.id_psg where DATEPART(weekday, pit.date) = 7 and CAST(t.time_out as time) > CAST(t.time_in as time)
group by p.id_psg, p.name
/* 111
Get the squares that are NEITHER white NOR black, and painted with different colors in a 1:1:1 ratio. Result set: square name, paint quantity for a single color
*/
WITH aggregates AS
(
	SELECT q.Q_NAME, v.V_COLOR, SUM(b.B_VOL) AS overall FROM utB b JOIN utV v ON b.B_V_ID = v.V_ID JOIN utQ q ON q.Q_ID = b.B_Q_ID
	GROUP BY q.Q_ID, q.Q_NAME, v.V_COLOR
)
SELECT a.Q_NAME, MAX(a.overall) FROM aggregates a
GROUP BY a.Q_NAME
HAVING COUNT(*) = 3 AND MIN(a.overall) <> 255 AND MIN(a.overall) = MAX(a.overall)
/* 112
What maximal number of black squares could be colored white using the remaining paint?
*/

/* 113
How much paint of each color is needed to dye all squares white?
Result set: amount of each paint in order (R,G,B).
*/
WITH all_cols AS
(
	SELECT * FROM utQ q	CROSS JOIN (SELECT 'R' AS Color
	UNION ALL
	SELECT 'B'
	UNION ALL
	SELECT 'G') AS cj
), STATEMENT AS
(
	SELECT q.Q_NAME, q.Color, SUM(ISNULL(b.B_VOL, 0)) AS vol FROM utB b JOIN utV v ON
	b.B_V_ID = v.V_ID RIGHT JOIN all_cols q ON q.Q_ID = b.B_Q_ID AND q.Color = v.V_COLOR
	GROUP BY q.Q_NAME, q.Color
)--SELECT * FROM STATEMENT
--ORDER BY Q_NAME
SELECT SUM(CASE WHEN s.Color = 'R' THEN 255 - s.vol END) AS [Red],
SUM(CASE WHEN s.Color = 'G' THEN 255 - s.vol END) AS [Green],
SUM(CASE WHEN s.Color = 'B' THEN 255 - s.vol END) AS [Blue]
FROM STATEMENT s

/* 114
Find the names of different passengers who occupied the same seat most often. Output: passenger name, number of flights in the same seat.
*/
select p.name, tt.dr from (
	select TOP 1 WITH TIES t.id_psg, max(t.n) as dr FROM
		(
		SELECT id_psg, place, COUNT(*) n
		FROM pass_in_trip
		GROUP BY id_psg, place
		) t
        group by t.id_psg
        order by max(t.n) desc
) tt
inner join passenger p on p.id_psg = tt.id_psg
/* 115
Let’s consider isosceles trapezoids, each of them having an inscribed circle tangent to all four sides. Besides, each side has an integer length belonging to the set of b_vol values.
Output the result in 4 columns named Up, Down, Side, Rad, where Up is the shorter base, Down - the longer base, Side is the length of the legs, and Rad - the radius of the inscribed circle (with 2 decimal places).
*/

/* 116
Assuming a painting event lasts exactly one second determine all continuous time intervals in the utB table that are more than one second long.
Output: date of the painting event that starts the respective interval, date of the painting event that ends it.
*/
with distinct_vals as
(
select b_datetime from utB group by b_datetime
)
,intervals as 
(
 select distinct b_datetime, dateadd(second, -row_number() over(order by b_datetime asc), b_datetime) as nxt from distinct_vals 
)select min(b_datetime), max(b_datetime) from intervals
group by nxt having count(*) > 1;

/* 117
For each country in the Classes table, determine the maximal value among the following three expressions:
numguns*5000, bore*3000, displacement.
The result set consists of 3 columns:
- country;
- maximal value;
- the word "numguns" if numguns*5000 is the maximum, "bore" if it’s bore*3000, or "displacement" if it’s the displacement.
Note. If the maximum occurs for more than one expression, display them all in a separate row each.
*/
SELECT Top 1 WIth ties country, value, name
FROM Classes
CROSS APPLY
(
VALUES
('numGuns', numGuns*5000)
,
('bore', bore*3000)
,
('displacement', displacement)
)
AS spec(name, value)
Group BY country, name, value
order by rank()over(partition by country order by value desc)
/* 118
The PFAS Museum Director elections are held in leap years only, on the first Tuesday after the first Monday in April.
For each date from the Battles table, determine the closest election date following it.
Output: battle name, date of battle, election date. Note: output format for dates should be "yyyy-mm-dd". 
*/
-- Surely this solution can be optimized -- 
WITH min_max_dts AS
(
	SELECT MIN(b.date) AS min_date, MAX(b.date) AS max_date FROM Battles b
),
nums1 AS (SELECT 1 AS n FROM (VALUES(1), (1), (1), (1)) AS d(n)),
nums2 AS (SELECT 1 AS n FROM nums1 n1 CROSS JOIN nums1 n2),
nums3 AS (SELECT 1 AS n FROM nums2 n1 CROSS JOIN nums2 n2),
nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS num FROM nums3),
gen_nums AS (SELECT n.num FROM nums n JOIN min_max_dts mmd ON n.num <= YEAR(mmd.max_date) - YEAR(mmd.min_date) + 4),
leap_years AS (
	SELECT mmd.min_date, gn1.num - 1 AS num FROM min_max_dts mmd
	JOIN gen_nums gn1 ON (YEAR(mmd.min_date) + gn1.num - 1) % 4 = 0 AND (NOT ((YEAR(mmd.min_date) + gn1.num - 1) % 100 = 0)) OR ((YEAR(mmd.min_date) + gn1.num - 1) % 400 = 0) 
), days AS
( SELECT *, DATEFROMPARTS(YEAR(mmd.min_date) + mmd.num, 4, gn2.numeq) AS dtfromparts FROM leap_years mmd
	CROSS APPLY (
		SELECT TOP (1) gn.num + 1 AS numeq FROM nums gn 
		WHERE  gn.num <= 10  AND DATENAME(WEEKDAY, DATEFROMPARTS(YEAR(mmd.min_date) + mmd.num, 4, gn.num)) = 'Monday'
		ORDER BY DATEFROMPARTS(YEAR(mmd.min_date) + mmd.num, 4, gn.num)
	) AS gn2
)
SELECT b.name, CONVERT(date, b.date,20), d.dtfromparts FROM Battles b 
CROSS APPLY (
	SELECT TOP(1) * FROM days d
	WHERE b.date < d.dtfromparts
	ORDER BY d.dtfromparts ASC
	) AS d


/* 119
Group all paintings by days, months and years separately. The group identifiers should be "yyyy" for years, "yyyy-mm" for months and "yyyy-mm-dd" for days.
Displayed should be only groups with more than 10 distinct moments of time (b_datetime) at which paintings have occurred.
Result set: group identifier, total quantity of paint used within a group.
*/

WITH resultset AS (
SELECT
	 CASE GROUPING_ID(YEAR(b.B_DATETIME),MONTH(b.B_DATETIME),DAY(b.B_DATETIME)) 
	 -- WHEN 1 then DAY is NULL then grouping by year and month 
		WHEN 0 THEN 
		CONCAT(YEAR(b.B_DATETIME),'-',CASE WHEN MONTH(b.B_DATETIME) < 10 THEN '0' ELSE NULL END, MONTH(b.B_DATETIME), '-',
			CASE WHEN DAY(b.B_DATETIME) < 10 THEN '0' ELSE NULL END, DAY(b.B_DATETIME))
		WHEN 1 THEN CONCAT(YEAR(b.B_DATETIME),'-',CASE WHEN MONTH(b.B_DATETIME) < 10 THEN '0' ELSE NULL END, MONTH(b.B_DATETIME))
		WHEN 3 THEN CAST(YEAR(b.B_DATETIME) AS varchar)
	 END AS dt,
SUM(b.B_VOL) AS vol, COUNT(DISTINCT b.b_DATETIME) AS cnt   FROM utB b
GROUP BY GROUPING SETS
(
	(YEAR(b.B_DATETIME)), --by year
	(YEAR(b.B_DATETIME), MONTH(b.B_DATETIME)), -- year/month
	(YEAR(b.B_DATETIME), MONTH(b.B_DATETIME), DAY(b.B_DATETIME))
)
)
SELECT r.dt, r.vol FROM resultset r
WHERE r.cnt > 10

/* 120
For each airline that has transported at least one passenger, calculate the arithmetic, geometric, quadratic and harmonic means of its respective planes’ flight durations (in minutes) with an accuracy of two decimal places. In addition, output the aforementioned characteristics for all flights in a separate line, using the word ‘TOTAL’ as the airline name.
Result set: company name, arithmetic mean {(x1 + x2 + … + xN)/N}, geometric mean {(x1 * x2 * … * xN)^(1/N)}, quadratic mean { sqrt((x1^2 + x2^2 + ... + xN^2)/N)}, harmonic mean {N/(1/x1 + 1/x2 + ... + 1/xN)}.
*/

/* 121
Get the names of all ships in the database that definitely were launched before 1941
*/

/* 122
Assuming the first town a passenger departs from is his/her residence, find out the passengers who are away from home. Result set: passenger name, town of residence. 
*/
WITH aggregate AS
(
SELECT pit.ID_psg, MIN(CONVERT(VARCHAR(8), pit.[date], 112)+CONVERT(VARCHAR(9), t.[time_out], 108)+t.town_from) AS min_town,
MAX(CONVERT(VARCHAR(10), pit.[date], 112)+CONVERT(VARCHAR(9), t.[time_out], 108)+t.town_to) AS max_town
FROM Pass_in_trip pit JOIN Trip t ON t.trip_no = pit.trip_no
GROUP BY pit.ID_psg
)
SELECT p.name,X1.val1 FROM aggregate a
JOIN Passenger p on a.ID_psg = p.ID_psg
CROSS APPLY (VALUES(SUBSTRING(a.min_town, 17, LEN(a.min_town)))) AS X1(val1)
CROSS APPLY (VALUES(SUBSTRING(a.max_town, 17, LEN(a.max_town)))) AS X2(val1)
WHERE X1.val1 <> X2.val1
/* 123
For each maker find out the number of available products (of any type) with a non-unique price and the number of such non-unique prices.
Result set: maker, number of products, number of prices.
*/
with all_ava_prods AS
(Select code, model, price from pc
union all
select code, model, price from laptop
union all
select code, model, price from printer
), maker_prods AS
(
 SELECT p.maker, avp.*, row_number() over(partition by p.maker order by avp.price) as rn FROM product p LEFT JOIN all_ava_prods avp ON p.model = avp.model
), maker_non_unique AS
(
 SELECT * FROM maker_prods mp 
 WHERE EXISTS (select 1 FROM maker_prods mp2 
   where mp2.price = mp.price and mp2.maker = mp.maker
and mp.rn <> mp2.rn
  )
), results AS
(
select maker, count(code) as cnt1, count(distinct price) cnt2 from maker_non_unique
group by maker
)
select p.maker, case when mnu.cnt1 is null then 0 else mnu.cnt1 end, case when mnu.cnt2 is null then 0 else mnu.cnt2 end from 
product p left join results mnu on p.maker = mnu.maker
GROUP BY p.maker, case when mnu.cnt1 is null then 0 else mnu.cnt1 end, case when mnu.cnt2 is null then 0 else mnu.cnt2 end
/* 124
Among the passengers who flew with at least two airlines find those who traveled the same number of times with each of these airlines. Display the names of such passengers.
*/
WITH cte AS
(
SELECT pit.ID_psg, t.ID_comp, COUNT(pit.trip_no) AS num_of_flights FROM Pass_in_trip pit JOIN Trip t ON pit.trip_no = t.trip_no 
GROUP BY pit.ID_psg, t.ID_comp
)
SELECT p.name FROM Passenger p JOIN cte c ON p.ID_psg = c.ID_psg
GROUP BY p.name, p.ID_psg
HAVING COUNT(c.ID_comp) > 1 AND MIN(num_of_flights) = MAX(num_of_flights)
/* 125
Put all data about models on sale and their prices (from the tables Laptop, PC and Printer) into a single table named LPP, and enumerate its records (by assigning an id to each row) without gaps or duplicates.
Assume the models in each of the original three tables to be sorted in ascending order by the code field. The unified LPP table numbering has to be set up according to the following rule: first go the first models from the tables (Laptop, PC, and Printer), then the last models, after that - the second models in the original tables, then, the penultimate ones, etc.
In case there are no models of a particular type left, number the remaining models of other types only.
Output the LPP table in 4 columns: id, type, model, and price. The type field contains one of the strings 'Laptop', 'PC', or 'Printer'.
*/
WITH laptops AS
(
	SELECT 'Laptop' AS type, code, model, price, 1 AS [order], ROW_NUMBER() OVER(ORDER BY code ASC) AS rn FROM Laptop L
	
), laptops_calcs
AS
(
		SELECT *, ROW_NUMBER() OVER(ORDER BY ABS(D.val - rn) DESC, code ASC) AS rn_true FROM laptops
		CROSS APPLY (SELECT AVG(1.0 * rn) FROM laptops) AS D(val)
),
--PCs
 PCs AS
(
	SELECT 'PC' AS type, code, model, price, 2 AS [order], ROW_NUMBER() OVER(ORDER BY code ASC) AS rn FROM PC 
	
), PCs_calcs
AS
(
		SELECT *, ROW_NUMBER() OVER(ORDER BY ABS(D.val - rn) DESC, code ASC) AS rn_true FROM Pcs
		CROSS APPLY (SELECT AVG(1.0 * rn) FROM PCs) AS D(val)
),
--Printers
 Printers AS
(
	SELECT 'Printer' AS type, code, model, price, 3 AS [order], ROW_NUMBER() OVER(ORDER BY code ASC) AS rn FROM Printer 
	
), Printers_calcs
AS
(
		SELECT *, ROW_NUMBER() OVER(ORDER BY ABS(D.val - rn) DESC, code ASC) AS rn_true FROM Printers
		CROSS APPLY (SELECT AVG(1.0 * rn) FROM Printers) AS D(val)
)
SELECT ROW_NUMBER() OVER(ORDER BY rn_true, [order]) as ID, type, model, price FROM
(
	SELECT type, model, price, rn_true, [order] FROM laptops_calcs
	UNION ALL
	SELECT type, model, price, rn_true, [order] FROM PCs_calcs
	UNION ALL
	SELECT type, model, price, rn_true, [order] FROM Printers_calcs
) AS X
/* 126
For the sequence of passengers ordered by id_psg find out the ones having the maximum number of flight bookings, as well as the ones directly preceding and following them in the sequence.
The first passenger in the sequence is preceded by the last one, and the last passenger is followed by the first one.
For each passenger meeting the aforementioned criterion, display his/her name, the name of the previous passenger, and the name of the next passenger.
*/
-- Solution which really needs to be optimalized (filtering phrase is at the end so I should try to push it earlier).
WITH min_max AS (
	SELECT MIN(id_psg) AS min_psg, MAX(id_psg) AS max_psg FROM Passenger
),
data AS
(
SELECT p.ID_psg, p.name, 
	DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS cnt, 
	LAG(p.name, 1, (
		SELECT p1.name from Passenger p1 where p1.id_psg = (
			SELECT max_psg FROM min_max)
			)
		) 
	OVER(ORDER by p.id_psg) AS prev, 
	LEAD(p.name, 1, (
		SELECT p1.name from Passenger p1 where p1.id_psg = (
			SELECT min_psg FROM min_max)
			)
		) 
	OVER(ORDER BY p.id_psg) AS nxt  
	FROM Pass_in_trip pit RIGHT JOIN Passenger p ON p.ID_psg = pit.ID_psg
GROUP BY p.ID_psg, p.name
)
SELECT d.name, d.prev, d.nxt FROM data d WHERE cnt = 1;
/* 127
Find out the arithmetic mean (rounded to hundredths) of the following prices:
1. Price of the cheapest Laptops produced by makers of PCs with the lowest CD-ROM speed;
2. Price of the most expensive PCs by makers of the cheapest printers;
3. Price of the most expensive printers by makers of Laptops with the greatest RAM capacity.
Note: Exclude missing prices from the calculation.
*/

/* 128
For each existing pair of buy-back centers from different tables (outcome and outcome_o) having the same identifier, determine the one with a greater total daily payout for each date at least one member of the pair collected recyclables.
Result set: buy-back center ID, date, one of the following messages:
- "once a day", if the center with only one payment per day possible has a greater payout;
- "more than once a day", if the payout is greater for the center with several transactions per day possible;
- "both", if both pair members paid out the same sum.
*/

/* 129
Assuming there are gaps in the sequence of ordered square IDs (Q_ID), find the minimum and maximum "free" values in the range between the least and the biggest existing IDs.
E.g., for a square ID sequence consisting of 1, 2, 5, 7, the result should be 3 and 6.
If there are no gaps in the sequence, display NULLs for both values. 
*/
WITH first_results AS (
SELECT u.Q_ID id, CASE WHEN LEAD(u.Q_ID, 1) OVER (ORDER BY u.Q_ID ASC) <> u.Q_ID + 1 THEN  LEAD(u.Q_ID, 1) OVER (ORDER BY u.Q_ID ASC) ELSE NULL END AS nxt_num  FROM utQ u
), resultset AS (
	SELECT r.id + 1 as prev, r.nxt_num - 1 as nxt from first_results r
	WHERE r.nxt_num IS NOT NULL
)
SELECT MIN(r.prev), MAX(r.nxt) FROM resultset r
/* 130
Historians decided to make a summary of battles and arrange it in two super columns. Each super column consists of three columns containing the battle serial number, name, and date.
First, the left super column is filled out in ascending order of serial numbers, then the right one. Serial numbers are assigned sequentially, with the battles being sorted by date, then by name.
In order to save paper the historians distribute the data from the Battles table equally between the two super columns (adding an extra battle to the left one if the total of battles is odd).
Display the result of the historians’ work as a six-column table, filling empty cells with NULL values.
*/
WITH numbered_battles AS
(
	SELECT b.name, b.date, ROW_NUMBER() OVER(ORDER BY b.date ASC, b.name ASC) as rn, d.cnt
	FROM Battles b CROSS JOIN (Select COUNT(*) FROM Battles) as d(cnt)
), grouped_battles AS
(
	SELECT name, date, rn,cnt, grp, ROW_NUMBER() OVER(PARTITION BY grp ORDER BY rn) AS rn_1 FROM (
		SELECT name, date, rn,cnt, 
		-- CASE --
		CASE cnt%2
			WHEN 0 THEN
				CASE WHEN rn <= cnt / 2 THEN 1 ELSE 2 END
			WHEN 1 THEN 
				CASE WHEN rn <= CEILING(CAST(cnt AS numeric(10,2)) / 2) THEN 1 ELSE 2 END
		END as grp
		FROM numbered_battles
	) AS d
)--naiwne podejscie XD
SELECT d1.rn, d1.name, d1.date, d2.rn, d2.name, d2.date FROM (SELECT name, date, rn, grp, rn_1 FROM grouped_battles g WHERE grp = 1) AS d1
LEFT JOIN (SELECT name, date, rn, grp, rn_1 FROM grouped_battles g WHERE grp = 2) AS d2
ON d1.rn_1 = d2.rn_1
/* 131
Select cities from the Trip table whose names contain at least 2 different vowels from the list (a,e,i,o,u), with all these letters occurring an equal number of times in the name. 
*/

/* 132
For the date of each battle (date1), take the date of the chronologically subsequent battle (date2); if there is no such battle, use the current date.
Determine the age (the number of full years and full months) a person born on date1 reaches on date2.
Notes:
1) assume a full month of age is reached on the day matching the birthday, or earlier if the month in question doesn’t have any subsequent days;
a full year consists of 12 full months; all battles took place on different dates before today.
2) represent the dates in "yyyy-mm-dd" format without the time part, and the age in "Y y., M m." format; omit the number of years or months if the corresponding value is 0; display an empty string for an age of less than 1 full month.
Output: age, date1, date2.
*/

/* 133
Let S be a subset of the set of integers.
Let’s call "a hill with N on its top" a sequence of members of S consisting of numbers less than N arranged in ascending order from left to right and concatenated to a string without delimiters, followed by the same numbers arranged in descending order, and the value of N lying in between. E. g., for S={1,2,...,10}, the hill with 5 on its top is represented as 123454321.
Assuming S consists of all company identifiers, put together a hill for each company, with its ID forming the top of the hill.
Consider all IDs to be positive and note there is no data in the database that can cause the hill sequence exceed 70 digits.
Result set: id_comp, hill sequence
*/
WITH hill AS (
	SELECT c.ID_comp, (
		SELECT CAST(''+ c1.ID_comp AS VARCHAR(MAX))
		FROM Company c1
		WHERE c1.ID_comp <= c.ID_comp
		FOR XML PATH('')
	) AS lower_hill,
		(
		SELECT CAST(''+ c1.ID_comp AS VARCHAR(MAX))
		FROM Company c1
		WHERE c1.ID_comp <= c.ID_comp
		ORDER BY c1.ID_comp DESC
		OFFSET 1 ROWS
		FOR XML PATH('')
		)
	AS upper_hill
	FROM Company c
) 
SELECT ID_comp, CONCAT(lower_hill, upper_hill) FROM hill
/* 134
To make the squares white, additional paint of each color is applied to them according to the following scheme:
- first, squares needing the least amount of paint of a given color are dyed;
- in case the amount of needed paint is equal, squares with smaller Q_IDs are dyed first.
Find the IDs of the squares that still AREN’T white after all of the paint has been used up.
*/

/* 135
For each one-hour interval starting on the hour during which squares were dyed, determine the last moment of a painting event (B_DATETIME).
*/

SELECT MAX(b_datetime) FROM utB
GROUP BY CAST(CONVERT(varchar, b_datetime, 112) + ' '+LEFT(CONVERT(varchar, B_DATETIME, 114), 2) + ':00' AS datetime2)
-- Forgot about DATEPART function
SELECT MAX(b_datetime) FROM utB
GROUP BY CAST(B_DATETIME AS date), DATEPART(HOUR, B_DATETIME)

/* 136
For each ship in the Ships table whose name contains symbols that aren't letters of the English alphabet, display its name, the position of the first such non-alphabetic character, and the character itself. 
*/
SELECT s.name, d.pat, SUBSTRING(s.name,d.pat, 1) t  FROM Ships s
CROSS APPLY ( 
	VALUES(PATINDEX('%[" "-,.*!@#$^&()''""|\/_`~<>;:}{+=1234567890]%', s.name)) 
		)
	AS d(pat)
WHERE d.pat <> 0
/* 137
For each fifth model (in ascending order of model numbers) in the Product table, find out its product type and average price. 
*/
with all_models AS
(
	SELECT model, price FROM PC
	UNION ALL 
	SELECT model, price FROM Printer
	UNION ALL 
	SELECT model, price FROM Laptop
), grouped_models AS 
(
	SELECT p.model, MAX(p.type) as type, AVG(a.price) as avg_price FROM Product p LEFT JOIN all_models a ON p.model = a.model
GROUP BY p.model
), numbered AS
(
	SELECT model, type, avg_price, ROW_NUMBER() OVER(Order by model ASC) as rn FROM grouped_models
)
SELECT TYPE, avg_price FROM numbered WHERE rn % 5 = 0
/* 138
Determine all unique pairs of non-black squares (q_id1 and q_id2) painted by the same set of spray cans.
Output: q_id1, q_id2, where q_id1 < q_id2. 
*/

/* 139
For each ship not present in the Outcomes table, obtain the comma-separated chronological list of battles it couldn’t have participated in. If there are no such battles, output NULL.
Assume a ship could have taken part in any battle that happened in the year the vessel was launched.
Output: ship name, list of battles.
*/
WITH ships_dates AS
(
	SELECT s1.name, s1.launched launch_ship, s2.launched  launch_class FROM Ships s1
	LEFT JOIN Ships s2 ON s1.class = s2.name
)
SELECT S.NAME, STRING_AGG(b.name, ',') WITHIN GROUP (order by b.date)
 AS battle_list
FROM ships_dates s LEFT JOIN Battles b ON CASE WHEN s.launch_ship IS NULL THEN s.launch_class ELSE s.launch_ship END > YEAR(b.date)
WHERE s.name NOT IN (select ship FROM Outcomes)
GROUP BY s.name
/* 140
For the period from the earliest battle in the database to the last one, find out how many battles happened during each decade.
Result set: decade (in "1940s" format); number of battles.
*/
WITH nums1 AS (select 1 as n from (values(1),(1),(1),(1),(1),(1)) as d(n))
, nums2 AS (SELECT 1 as n FROM nums1 n1 CROSS JOIN nums1 n2)
, rns AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as rn FROM nums2)
, max_yrs AS (
	SELECT MIN(DATEPART(year, date)/10)*10 as min_yr, MAX(DATEPART(year, date)/10)*10 as max_yr FROM Battles
), gen_decades AS 
(
	SELECT min_yr + (rn - 1) * 10  AS yr  FROM max_yrs JOIN rns ON min_yr + (rn - 1) * 10 <= max_yr
)
SELECT CAST(gd.yr AS varchar(4)) + 's', COUNT(b.name) FROM gen_decades gd LEFT JOIN Battles b ON gd.yr = (DATEPART(year, b.date)/10)*10
GROUP BY gd.yr
/* 141
For each travelled passenger, determine the number of days in April, 2003 lying between the dates of the passenger’s first and last departure inclusive.
Display the passenger’s name and the number of days. 
*/
WITH min_maxes AS
(
	SELECT pit.ID_psg, MIN(pit.[date]) AS min_dt, MAX(pit.[date]) AS max_dt FROM Pass_in_trip pit
	GROUP BY pit.ID_psg
), dates_of_interest AS
(
	SELECT  mm.ID_psg, mm.min_dt, mm.max_dt, CASE WHEN 
		(mm.min_dt BETWEEN '20030401' AND '20030430') OR (mm.max_dt BETWEEN '20030401' AND '20030430')
		OR (mm.min_dt < '20030401' AND mm.max_dt > '20030430') THEN 1 ELSE 0 END AS flag
		FROM min_maxes mm
)
SELECT p.name, X.val AS cnt 
FROM dates_of_interest doi JOIN Passenger p ON doi.ID_psg = p.ID_psg
CROSS APPLY 
	(
		VALUES(CASE WHEN doi.flag = 1 THEN (DATEDIFF(DAY, CASE WHEN doi.min_dt < '20030401' THEN '20030401' ELSE doi.min_dt END , CASE WHEN doi.max_dt > '20030430' THEN '20030430' ELSE doi.max_dt END ) + 1) ELSE 0 END) 
	) AS X(val);
/* 142
Among the passengers who only flew by the planes of the same model, find names of those who arrived at the same town at least twice. 
*/
SELECT name FROM Passenger p
WHERE p.ID_psg IN (
	SELECT pit.Id_psg FROM Pass_in_trip pit JOIN Trip t ON pit.trip_no = t.trip_no
		GROUP BY pit.ID_psg
	HAVING MAX(t.plane) = MIN(t.plane) AND COUNT(*) - COUNT(DISTINCT t.town_to) >= 1
)
/* 143
For each battle, find out the date of the last Friday of the month this battle occurred in.
Output: battle, date of battle, date of the last Friday of the month.
Display the dates in "yyyy-mm-dd" format.
*/
WITH nums AS
(
	SELECT 0 AS n
	UNION ALL
	SELECT n + 1 AS n FROM nums
	WHERE n < 6
)
SELECT b.name, CAST(b.date AS date), DATEADD(day, -n , EOMONTH(b.date)) FROM Battles b JOIN Nums n
ON DATEPART(dw, DATEADD(day, -n , EOMONTH(b.date))) = DATEPART(dw, '20210326')
/* 144
Get the manufacturers producing both the cheapest and the most expensive PCs.
Output: maker. 
*/
WITH all_1 AS
(
	SELECT p.maker, p.model, pc.price FROM Product p JOIN PC pc ON p.model = pc.model
), min_max AS
(
	SELECT MIN(price) as minp, MAX(price) as maxp FROM PC
)
SELECT a1.maker FROM all_1 a1
WHERE a1.price = (SELECT minp FROM min_max)
INTERSECT
SELECT a1.maker FROM all_1 a1
WHERE a1.price =(SELECT maxp FROM min_max)
/* 145
For each pair of consecutive dates in the Income_o table denoted as dt1 and dt2, determine the sum of payments according to the Outcome_o table within the half-closed interval of dates (dt1, dt2].
Output: sum of payments, dt1, dt2. 
*/

/* 146
For the PC in the PC table with the maximum code value, obtain all its characteristics (except for the code) and display them in two columns:
- name of the characteristic (title of the corresponding column in the PC table);
- its respective value.
*/
WITH cte AS
(
	SELECT TOP (1) CAST(pc.cd AS VARCHAR(50)) cd, CAST(pc.hd AS VARCHAR(50)) hd, CAST(pc.model AS VARCHAR(50)) model,
	CAST(pc.price AS VARCHAR(50)) price, CAST(pc.ram AS VARCHAR(50)) ram, CAST(pc.speed AS VARCHAR(50)) speed
	FROM PC pc
	ORDER BY code DESC
)
SELECT chr, value FROM cte c
CROSS APPLY (VALUES('cd', [cd]), ('hd', [hd]), ('model', [model]), ('price', [price]), ('ram', [ram]), ('speed', [speed])) AS X(chr, value)
/* 147
Number the rows of the Product table as follows: makers in descending order of number of models produced by them (for manufacturers producing an equal number of models, their names are sorted in ascending alphabetical order); model numbers in ascending order.
Result set: row number as described above, manufacturer's name (maker), model.
*/
WITH cnts AS
(
	SELECT p.maker, COUNT(*) AS cnt FROM Product p
	GROUP BY p.maker
)
SELECT ROW_NUMBER() OVER( ORDER BY c.cnt DESC, p.maker ASC, p.model ASC ), p.maker, p.model FROM Product p JOIN cnts c ON p.maker = c.maker
/* 148
In the Outcomes table, transform the names of the ships containing more than one space as follows:
replace all characters between the first and the last spaces (excluding these spaces) by asterisks (*).
The number of asterisks has to be equal to the number of replaced characters.
Result set: ship name, transformed ship name. 
*/
WITH cte AS (
	SELECT o.ship, occ_1st_space.sp as frst_occ, occ_lst_space.sp AS lst_occ, LEN(o.ship) as ln FROM Outcomes o
	CROSS APPLY (VALUES
					(CHARINDEX(' ', o.ship, 1))
		) AS occ_1st_space(sp)
	CROSS APPLY (
		VALUES(
			DATALENGTH(o.ship) - CHARINDEX(' ', REVERSE(o.ship), 1 ) + 1
			)
		) AS occ_lst_space(sp)
	WHERE NOT (occ_1st_space.sp = occ_lst_space.sp OR occ_1st_space.sp = 0 OR occ_lst_space.sp = 0)
)
SELECT c.ship, STUFF(c.ship, c.frst_occ + 1, c.lst_occ - 1 - c.frst_occ , REPLICATE('*', c.lst_occ - 1 - c.frst_occ)) FROM cte c
/* 149
Determine the upper limit of the interval (B_DATETIME <= MinTime), during which each spray can in the utB table has been used at least once.
Display the names of different spray cans being in use at this moment.
*/

/* 150
For each point in the Income table, determine the minimum (min_date) and maximum (max_date) dates of receiption of funds.
In the time-ordered sequence of all records in the Income table for each interval [min_date, max_date]
define one closest row above (date1 < min_date) and closest below (date2 > max_date).
In other words, it is required to extend each interval by one row above and below. If the wanted row/rows are absent, consider the date1 / date2 value to be undefined (NULL).
Output: point, date1, min_date, max_date, date2.
*/

/* 151
For each ship from the Ships table, determine the name of the earliest battle from the Battles table it could have participated in after being launched.
If the year the ship has been launched is unknown use the latest battle.
If no battles occurred after the ship was launched, display NULL instead of the battle name.
It’s assumed a ship can participate in any battle fought in the year of its launching.
Result set: name of the ship, year it was launched, name of battle.

Note: assume there are no battles fought at the same day. 
*/

/* 152

The Product table is considered. Printers sorted by model form groups (with models representing group numbers). PC models (sorted from the lowest model to the largest one) are added one by one to each printer's group (in ascending order). After another PC is added to the last group, the process is resumed from the first group, and goes on in the same manner till the PC models are exhausted. Number the records as follows: printer models according to group model, then PС models belonging to the group.
Output: record number, model, type
Note. Laptop models should not be taken into account or displayed. 
*/

/* 153
Find the names of different passengers who ever travelled twice in a row occupying seats with the same number. 
*/
WITH cte AS
(
SELECT p.ID_psg, p.name, place,
	LEAD(pit.place, 1, '') OVER(PARTITION BY pit.id_psg ORDER BY pit.[date], t.time_out) AS nxt_place
	FROM Pass_in_trip pit JOIN Trip t ON pit.trip_no = t.trip_no
	JOIN Passenger p ON p.ID_psg = pit.ID_psg
)
SELECT c.name FROM cte c
WHERE c.place = c.nxt_place
GROUP BY c.id_psg, c.name
/* 154
Assume that in all tables the point field with the same number indicates the same point.
For each point, calculate the amount of expense and income for each day when there were transactions with this item separately according to the tables with statements once a day and separately with reports several times a day.
If on one day the item had operations both on reporting once a day and on reporting several times a day, then such data should not be output.

Output: point, date, amount of receipt, amount of expense, 'once' - if the type of operation is once a day and 'several' if several.
Note: If there is no income/outcome, output 0.
*/

/* 155
Assuming there is no flight number greater than 65535, display the flight number and its binary representation (without leading zeroes). 
*/
WITH nums AS
(
	SELECT 1 AS num
	UNION ALL
	SELECT num * 2 FROM nums
	where num * 2 < 65535
), resultset AS
(
	SELECT t.trip_no, n.num, CAST(t.trip_no & n.num AS bit) as val FROM nums n CROSS JOIN Trip t
)
, resultsetX2 AS
(
	SELECT r.trip_no, STRING_AGG(CAST(r.val AS char(1)), '') WITHIN GROUP(ORDER BY r.num DESC) AS num FROM resultset r
	GROUP BY r.trip_no
) SELECT r.trip_no, SUBSTRING(r.num, CHARINDEX('1', r.num, 1), LEN(r.num) - CHARINDEX('1', r.num, 1) + 1) FROM resultsetX2 r
--Another one - the best in performance
SELECT t.trip_no,
CAST(
	CONCAT(
		t.trip_no / POWER(2,16) % 2,
		t.trip_no / POWER(2,15) % 2,
		t.trip_no / POWER(2,14) % 2,
		t.trip_no / POWER(2,13) % 2,
		t.trip_no / POWER(2,12) % 2,
		t.trip_no / POWER(2,11) % 2,
		t.trip_no / POWER(2,10) % 2,
		t.trip_no / POWER(2,9) % 2,
		t.trip_no / POWER(2,8) % 2,
		t.trip_no / POWER(2,7) % 2,
		t.trip_no / POWER(2,6) % 2,
		t.trip_no / POWER(2,5) % 2,
		t.trip_no / POWER(2,4) % 2,
		t.trip_no / POWER(2,3) % 2,
		t.trip_no / POWER(2,2) % 2,
		t.trip_no / POWER(2,1) % 2,
		t.trip_no / POWER(2,0) % 2
	)
	AS decimal -- Cast to number datatype so leading zeroes will be ommitted
) 
FROM Trip t