/* 51
Find the names of the ships with the largest number of guns among all ships having the same displacement (including ships in the Outcomes table). 
*/
with all_ships(name, displacement, numGuns) as(
select s.name, c.displacement, c.numGuns from classes c join ships s on s.class = c.class
union
select o.ship, c.displacement, c.numGuns from classes c inner join outcomes o on o.ship = c.class
)
, rns as (
select name, displacement, numGuns, dense_rank() over(partition by displacement order by numGuns desc) as dr from all_ships
where numGuns is not null and displacement is not null
)
select name from rns where dr = 1;

/* 52
Determine the names of all ships in the Ships table that can be a Japanese battleship having at least nine main guns with a caliber of less than 19 inches and a displacement of not more than 65 000 tons. 
*/
select s.name from ships s inner join classes c on
c.class = s.class
where country = 'Japan'
and type = 'bb'
and (numGuns is null or numGuns >=9)
and (bore is null or bore < 19)
and (displacement is null or displacement<= 65000) 
/* 53
With a precision of two decimal places, determine the average number of guns for the battleship classes. 
*/
Select cast(avg(cast(numGuns as decimal(10,2))) as decimal(5,2)) from classes
where type = 'bb'
/* 54
With a precision of two decimal places, determine the average number of guns for all battleships (including the ones in the Outcomes table). 
*/
with all_ships as (
select s.name, cast(c.numGuns as decimal(5, 2)) as numGuns from ships s inner join classes c on c.class = s.class
where c.type = 'bb'
union
select c.class, cast(c.numGuns as decimal(5, 2)) as numGuns from classes c inner join outcomes o on o.ship = c.class
where c.type = 'bb'
)
select cast(avg(numGuns) as decimal(4,2)) from all_ships

/* 55
For each class, determine the year the first ship of this class was launched.
If the lead ship�s year of launch is not known, get the minimum year of launch for the ships of this class.
Result set: class, year.
*/
Select c.class, min(s.launched) from ships s right join classes c on c.class = s.class
group by c.class
/* 56
For each class, find out the number of ships of this class that were sunk in battles.
Result set: class, number of ships sunk.
*/
Use Ship
with ships1 as (
select c.class, o.result, o.ship from classes c left join outcomes o on o.ship = c.class
union
select s.class, o.result, s.name from outcomes o join ships s on o.ship = s.name
)
select class, sum(case when result = 'sunk' then 1 else 0 end)
from ships1
group by class;

/* 57
For classes having irreparable combat losses and at least three ships in the database, display the name of the class and the number of ships sunk. 
*/
WITH all_ships AS
(
	select  c.class, o.ship, o.result FROM Classes c JOIN Outcomes o ON c.class = o.ship
	UNION 
	select  s.class, s.name, c.result FROM Outcomes c RIGHT JOIN Ships s ON c.ship = s.name
), partitioned AS
(
	SELECT als.*, ROW_NUMBER() OVER(PARTITION BY class, ship ORDER BY als.result DESC) AS rn FROM all_ships als
)
--SELECT * FROM partitioned
select p.class, COUNT(CASE WHEN p.result = 'sunk' THEN 1 END) as cs from partitioned p
WHERE p.rn = 1
GROUP BY p.class
HAVING COUNT(p.ship) >= 3 AND COUNT(CASE WHEN p.result = 'sunk' THEN 1 END) > 0
/* 58
For each product type and maker in the Product table, find out, with a precision of two decimal places, the percentage ratio of the number of models of the actual type produced by the actual maker to the total number of models by this maker.
Result set: maker, product type, the percentage ratio mentioned above.
*/
WITH product_table AS 
(
SELECT  p.maker, p.type, ROUND(1.0 * COUNT(*) OVER (PARTITION BY p.maker, p.type) / COUNT(*) OVER (PARTITION BY p.maker) * 100.0, 2) AS prc FROM Product p
)
select DISTINCT PT.maker, vals.val,	CAST(MAX(CASE WHEN pt.type <> vals.val THEN 0.0 ELSE pt.prc END) AS decimal(5,2)) as prc from product_table PT CROSS JOIN (SELECT DISTINCT type from Product) AS vals(val)
GROUP BY PT.maker, vals.val
/* 59
Calculate the cash balance of each buy-back center for the database with money transactions being recorded not more than once a day.
Result set: point, balance.
*/
with sums as
(
select point, inc from income_o
union all
select point, -out from outcome_o
)
select point, sum(inc) from sums
group by point
/* 60
For the database with money transactions being recorded not more than once a day, calculate the cash balance of each buy-back center at the beginning of 4/15/2001.
Note: exclude centers not having any records before the specified date.
Result set: point, balance
*/
with sums as
(
select point, inc from income_o
where date < '20010415'
union all
select point, -out from outcome_o
where date < '20010415'
)
select point, sum(inc) from sums
group by point

/* 61

For the database with money transactions being recorded not more than once a day,
 calculate the total cash balance of all buy-back centers
*/
with sums as
(
select inc from income_o
union all
select -out from outcome_o
)
select sum(inc) from sums
/* 62
For the database with money transactions being recorded not more than once a day, calculate the total cash balance of all buy-back centers at the beginning of 04/15/2001. 
*/
with sums as
(
select inc from income_o
where date < '20010415'
union all
select -out from outcome_o
where date < '20010415'
)
select sum(inc) from sums

/* 63
Find the names of different passengers that ever travelled more than once occupying seats with the same number. 
*/
Select p.name from Passenger p
where exists
(
    select null from Pass_in_trip pit
    where pit.Id_psg = p.ID_psg
    group by place
    having count(*) > 1
)
/* 64
Using the Income and Outcome tables, determine for each buy-back center the days when it received funds but made no payments, and vice versa.
Result set: point, date, type of operation (inc/out), sum of money per day.
*/
with cte as (
Select coalesce(i.point, o.point) as point,
coalesce(i.[date], o.[date]) as date,
case when i.date is not null then 'inc' else 'out' end as operation,
coalesce(i.inc, o.out) as money
from Income i full outer join Outcome o on i.point = o.point and i.[date] = o.[date]
where  i.point is null or o.point is null or i.[date] is null or o.[date] is null
)
select point, date, operation, sum(money)
from cte
group by point, date, operation

/* 65
Number the unique pairs {maker, type} in the Product table, ordering them as follows:
- maker name in ascending order;
- type of product (type) in the order PC, Laptop, Printer.
If a manufacturer produces more than one type of product, its name should be displayed in the first row only;
other rows for THIS manufacturer should contain an empty string (').
*/
WITH maker_prods AS
(
	SELECT  maker, type, ROW_NUMBER() OVER(PARTITION BY maker ORDER BY CASE
		WHEN type = 'PC' THEN 1
		WHEN type = 'Laptop' THEN 2
		WHEN type = 'Printer' THEN 3
	 END ASC) AS rn
	FROM Product
	GROUP BY maker, type
)
SELECT ROW_NUMBER() OVER(ORDER BY maker ASC, rn ASC) AS num, CASE WHEN rn = 1 THEN maker ELSE '' END AS maker,
type FROM maker_prods
/* 66
For all days between 2003-04-01 and 2003-04-07 find the number of trips from Rostov.
Result set: date, number of trips. 
*/
with l0 as (select 1 as n from (values(1), (1)) as c(n)),
l1 as (select 1 as n from l0 A cross join l0 B),
l2 as (select 1 as n from L1 A cross join l1 B),
rn as (select row_number() over(order by (select null)) as rown from l2),
date_gen as
(
	select dateadd(day, rown -1, '20030401')as dt
	from rn where rown<=7
)
Select dg.dt, count(distinct pit.trip_no) from Trip t inner join Pass_in_trip pit on pit.trip_no = t.trip_no and t.town_from = 'Rostov'
right outer join date_gen dg on dg.dt = pit.[date]
group by dg.dt

/* 67
Find out the number of routes with the greatest number of flights (trips).
Notes.
1) A - B and B - A are to be considered DIFFERENT routes.
2) Use the Trip table only. 
*/
With cte AS
(
select town_from, town_to, count(*) as rn  from trip 
group by town_from, town_to
)
select count(rn) from cte
where rn = (select max(rn) from cte)

/* 68
Find out the number of routes with the greatest number of flights (trips).
Notes.
1) A - B and B - A are to be considered the SAME route.
2) Use the Trip table only. 
*/
WITH trips AS (
SELECT towns.town_1, towns.town_2, COUNT(*) AS cnt, DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) as dr FROM Trip t1
	CROSS APPLY (VALUES(CASE WHEN town_from < town_to THEN town_from ELSE town_to END,CASE WHEN town_from < town_to THEN town_to ELSE town_from END)) AS towns(town_1, town_2)
	GROUP BY towns.town_1, towns.town_2
)
SELECT COUNT(*) FROM trips
WHERE dr = 1;
/* 69
Using the Income and Outcome tables, find out the balance for each buy-back center by the end of each day when funds were received or payments were made.
Note that the cash isn�t withdrawn, and the unspent balance/debt is carried forward to the next day.
Result set: buy-back center ID (point), date in dd/mm/yyyy format, unspent balance/debt by the end of this day. 
*/
WITH Inc_out AS
(
SELECT i.point, i.date, SUM(i.inc) AS inc FROM Income i
GROUP BY i.point, i.date
UNION ALL
SELECT i.point, i.date, -SUM(i.out) AS inc FROM Outcome i
GROUP BY i.point, i.date
), summed AS (
SELECT io.point, io.date,  SUM(SUM(io.inc)) OVER (PARTITION BY io.point ORDER BY io.date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rem FROM Inc_out io
GROUP BY io.point, io.date
)
SELECT s.point, CONVERT(VARCHAR(10), s.date, 103), s.rem FROM summed s;
/* 70
Get the battles in which at least three ships from the same country took part. 
*/
WITH ships_battles AS
(
SELECT class, country, battle FROM Classes c JOIN Outcomes o ON c.class = o.ship
UNION
SELECT name, country, battle FROM Outcomes o JOIN Ships s on o.ship = s.name JOIN Classes c ON s.class = c.class
), battles AS (
SELECT  battle FROM ships_battles s
GROUP BY country, battle
HAVING COUNT(*) >= 3
)
SELECT DISTINCT battle FROM battles -- needed to include this, because of a possibility when several countries, which ships ( >= 3) took part in a single battle - the result would be duplicated, but our need is to retrieve just a single name of a battle.

/* 71
Find the PC makers with all personal computer models produced by them being present in the PC table.
*/
select p.maker from product p where p.type = 'PC'
except
select p.maker from product p where p.type = 'PC'
and not exists
(
   select null from pc pc where pc.model = p.model
)
/* 72
Among the customers using a single airline, find distinct passengers who have flown most frequently. Result set: passenger name, number of trips. 
*/
with single_airline_custs AS
(
	SELECT p.name, p.id_psg FROM Passenger p JOIN Pass_in_trip pit ON p.id_psg = pit.id_psg
	JOIN Trip t ON t.trip_no = pit.trip_no 
	WHERE NOT EXISTS 
		(
			SELECT NULL FROM Pass_in_trip pit2 JOIN Trip t2 ON pit2.trip_no = t2.trip_no
			WHERE t.trip_no <> t2.trip_no AND pit.id_psg = pit2.id_psg AND t.id_comp <> t2.id_comp
		)
), aggregated_resultset AS
(
	SELECT sac.name, COUNT(sac.name) as trip_Qty FROM single_airline_custs sac
	GROUP BY sac.name, sac.id_psg
) SELECT name, trip_Qty FROM aggregated_resultset WHERE trip_Qty = (SELECT MAX(trip_Qty) FROM aggregated_resultset)
/* 73
For each country, determine the battles in which the ships of this country did not participate.
Result set: country, battle. 
*/
with cross_class_battle AS
(
	SELECT  c.country, o.name FROM Classes c CROSS JOIN Battles o
), fought_battles AS
(
	SELECT c.country, o.battle FROM Classes c JOIN Outcomes o ON c.class = o.ship
	UNION
	SELECT c.country, o.battle FROM Outcomes o JOIN Ships s ON o.ship = s.name JOIN Classes c ON c.class = s.class
)
SELECT * FROM cross_class_battle 
EXCEPT
SELECT * FROM fought_battles;
/* 74
Get all ship classes of Russia. If there are no Russian ship classes in the database, display classes of all countries present in the DB.
Result set: country, class. 
*/
Get all ship classes of Russia. If there are no Russian ship classes in the database, display classes of all countries present in the DB.
Result set: country, class. 
*/
USE Ships;
GO
WITH all_ships AS
(
	SELECT c.country, c.class FROM Classes c JOIN Ships s ON c.class = s.name
	UNION ALL
	SELECT c.country, c.class FROM Classes c JOIN Outcomes o ON o.ship = c.class
)--,joined_results AS
--(
SELECT als.country AS country1, als.class class1, als2.country country2, als2.class class2, CASE WHEN als2.country IS NULL THEN als.country ELSE als2.country END AS cntr,
CASE WHEN als2.class IS NULL THEN als.class ELSE als2.class END AS cls
FROM all_ships AS als
OUTER APPLY
	(
		SELECT als2.class, als2.country FROM all_ships als2 
		WHERE als2.country = 'Russia'
	) AS als2
)
SELECT DISTINCT jr.cntr AS country, jr.cls AS class  FROM joined_results AS jr
-- Another (better)
WITH all_classes AS (
	SELECT c.country country, c.class class, c2.country country2, c2.class class2 FROM Classes c
	OUTER APPLY (
		SELECT c2.class, c2.country FROM Classes c2 WHERE c2.country = 'Russia'
	) AS c2
)
SELECT DISTINCT CASE WHEN c.country2 IS NULL THEN c.country ELSE c.country2 END AS class, CASE WHEN c.class2 IS NULL THEN c.class ELSE c.class2 END AS class  FROM all_classes c
/* 75
For makers who have products with a known price in at least one of the Laptop, PC, or Printer tables, find the maximum price for each product type.
Output: maker, maximum price of laptops, maximum price of PCs, maximum price of printers. For missing products/prices, use NULL. 
*/
with cte
as
(
select model,price from printer
union all
select model,price from pc
union all
select model,price from laptop)

select t.* from (

select maker,price,p.type from Product p inner join cte on p.model=cte.model) as t
pivot (max(price)
for type in ([Laptop],[PC],[Printer]) )as t
where coalesce(t.Laptop, t.pc, t.Printer) is not null

/* 76
Find the overall flight duration for passengers who never occupied the same seat.
Result set: passenger name, flight duration in minutes. 
*/
SELECT p.name, SUM(
	CASE WHEN t.time_out > t.time_in THEN 1440 - DATEDIFF(minute, t.time_in, t.time_out)
		ELSE DATEDIFF(minute, t.time_out, t.time_in) END
	) AS minutes 
FROM Passenger p 
JOIN Pass_in_trip pit ON p.ID_psg = pit.ID_psg
JOIN Trip t ON pit.trip_no = t.trip_no
GROUP BY p.ID_psg, p.name
HAVING COUNT(DISTINCT pit.place) = COUNT(pit.place)
/* 77
Find the days with the maximum number of flights departed from Rostov. Result set: number of trips, date. 
*/
with rnk as(
Select count(distinct dt.trip_no) as cnt, dt.date, rank() over(order by count(distinct dt.trip_no) desc) as rn  from pass_in_trip dt join trip t on dt.trip_no = t.trip_no
where t.town_from = 'Rostov'
group by dt.date
)
select cnt, date from rnk where rn = 1;
/* 78
For each battle, get the first and the last day of the month when the battle occurred.
Result set: battle name, first day of the month, last day of the month.

Note: output dates in yyyy-mm-dd format. 
*/
select name, cast(dateadd(month, datediff(month, '19000101', date), '19000101') as date) as firstday,
cast(dateadd(month, datediff(month, '19000131', date), '19000131') as date) from battles;
/* 79
Get the passengers who, compared to others, spent most time flying.
Result set: passenger name, total flight duration in minutes. 
*/
with summd_mins as
(	select p.name,
	sum(c.mins)as mins 
	from trip t inner join pass_in_trip pit on pit.trip_no = t.trip_no
	inner join passenger p on p.id_psg = pit.id_psg
	cross apply(
		values(
			case when t.time_out < t.time_in then abs(datediff(minute, t.time_in, t.time_out))
			else 1440 - abs(datediff(minute, t.time_in, t.time_out)) end
				)
		) as c(mins)
group by p.id_psg, p.name
), ranked as (
select *, rank() over(order by mins desc) as rn from summd_mins
)
select name, mins from ranked where rn = 1;
/* 80
Find the computer equipment makers not producing any PC models absent in the PC table. 
*/
SELECT maker FROM PRODUCT
EXCEPT
SELECT  p.maker
FROM  product p
LEFT JOIN pc ON pc.model = p.model
WHERE p.type = 'PC' and pc.model is null
/* 81
For each month-year combination with the maximum sum of payments (out), retrieve all records from the Outcome table. 
*/
with summarized_dates as
(
Select year(date) yr, month(date) mn, sum(out) as summ, rank() over(order by sum(out) desc) as rn from outcome
group by year(date), month(date)
)
select o.* from outcome o inner join summarized_dates sd
on sd.yr = YEAR(o.date) and sd.mn = MONTH(o.date) and sd.rn = 1;

/* 82
Assuming the PC table is sorted by code in ascending order, find the average price for each group of six consecutive personal computers.
Result set: the first code value in a set of six records, average price for the respective set. 
*/
with cte as
(select *, avg(price) over(order by code asc rows between current row and 5 following) as avgprc,
count(*) over(order by code asc rows between current row and 5 following) as cnt from pc pc1
)
select code, avgprc from cte
where cnt = 6;
/* 83
Find out the names of the ships in the Ships table that meet at least four criteria from the following list:
numGuns = 8,
bore = 15,
displacement = 32000,
type = bb,
launched = 1915,
class = Kongo,
country = USA. 
*/
WITH criterias AS
(
	SELECT s.name,
	CASE WHEN numGuns = 8 THEN 1 ELSE 0 END AS crit1,
	CASE WHEN bore = 15 THEN 1 ELSE 0 END AS crit2,
	CASE WHEN displacement = 32000 THEN 1 ELSE 0 END AS crit3,
	CASE WHEN type = 'bb' THEN 1 ELSE 0 END AS crit4,
	CASE WHEN launched = 1915 THEN 1 ELSE 0 END AS crit5,
	CASE WHEN s.class = 'Kongo' THEN 1 ELSE 0 END AS crit6,
	CASE WHEN country = 'USA' THEN 1 ELSE 0 END AS crit7
	FROM Classes c JOIN Ships s ON c.class = s.class
)
SELECT name FROM criterias
WHERE crit1 + crit2 + crit3 + crit4 + crit5 + crit6 + crit7 >= 4;
/* 84
For each airline, calculate the number of passengers carried in April 2003 (if there were any) by ten-day periods. Consider only flights that departed that month.
Result set: company name, number of passengers carried for each ten-day period. 
*/
WITH timestamps AS 
(
Select c.name, 
CASE WHEN [date] BETWEEN CAST('20030401' as date) AND CAST('20030410' as date) THEN 1 
WHEN [date] BETWEEN CAST('20030411' as date) AND CAST('20030420' as date) THEN 2
ELSE 3 END as num FROM
Trip t inner join Pass_in_trip pit on t.trip_no = pit.trip_no
INNER JOIN Company c on c.ID_comp = t.ID_comp
WHERE [date] <= '20030430' AND [date] >= '20030401'
)
SELECT * FROM timestamps
PIVOT (
count(num) FOR num IN ([1], [2], [3])
) as pvt

/* 85
Get makers producing either printers only or personal computers only; in case of PC manufacturers they should produce at least 3 models
*/
SELECT		maker
FROM		product
GROUP BY	maker
HAVING		sum(CASE WHEN typE = 'Printer' THEN 1 END) = count(*)
		OR (sum(CASE WHEN type = 'PC' THEN 1 END) > = 3
			AND sum(CASE WHEN type = 'PC' THEN 1 END) = count(*))
/* 86
For each maker, list the types of products he produces in alphabetic order, using a slash ("/") as a delimiter.
Result set: maker, list of product types. 
*/
with distincted as
(
	select distinct maker, type from product
)
select distinct maker, STUFF((
	SELECT '/'+d1.type
	FROM distincted d1
	WHERE d1.maker = d.maker
	ORDER BY d1.type
	FOR XML PATH('')
	), 1, 1, ''
)	from
distincted d

/* 87
Supposing a passenger lives in the town his first flight departs from, find non-Muscovites who have visited Moscow more than once.
Result set: passenger's name, number of visits to Moscow. 
*/
select p.name, sum(case when t.town_to = 'Moscow' then 1 else 0 end ) from passenger p JOIN pass_in_trip pit ON p.id_psg = pit.id_psg JOIN trip t on pit.trip_no = t.trip_no
GROUP BY p.id_psg, p.name	
having MIN(pit.date + t.time_out) <> MIN(case when t.town_from = 'Moscow' then pit.date + t.time_out else '30000101 00:00:00' end)
AND sum(case when t.town_to = 'Moscow' then 1 else 0 end) > 1
/* 88
Among those flying with a single airline find the names of different passengers who have flown most often.
Result set: passenger name, number of trips, and airline name. 
*/
WITH all_cnts AS (
Select p.name as name, count(*) as cnt, c.name as Company, rank() over (order by count(*) desc) as rn
FROM Passenger p 
INNER JOIN Pass_in_trip pit ON pit.ID_psg = p.ID_psg
JOIN Trip t on t.trip_no = pit.trip_no
JOIN Company c ON c.ID_comp = t.ID_comp
WHERE NOT EXISTS
(
    SELECT NULL FROM Trip t2
INNER JOIN Pass_in_trip pit2 ON t2.trip_no = pit2.trip_no 
    WHERE t2.ID_comp <> t.ID_comp AND p.ID_psg = pit2.ID_psg
)
GROUP BY p.id_psg, p.name, c.name --take care about same credentials for different people
)
select name, cnt, Company from all_cnts WHERE rn = 1;
/* 89
Get makers having most models in the Product table, as well as those having least.
Output: maker, number of models. 
*/
with all_cnts AS 
(
    select maker, count(*) as cnt, min(count(*)) over() as rn_asc, max(count(*)) over() as rn_desc from product
    group by maker
)
select maker, cnt from all_cnts
where rn_asc = cnt or rn_desc = cnt;
/* 90
Display all records from the Product table except for three rows with the smallest model numbers and three ones with the greatest model numbers. 
*/
select * from product
order by model asc
offset 3 rows fetch next (select count(*) - 6 from product) rows only

/* 91
Determine the average quantity of paint per square with an accuracy of two decimal places.
*/
WITH all_results AS
(
	SELECT SUM(1.0 * ISNULL(b.B_VOL, 0.00)) AS sumb, COUNT(DISTINCT q.Q_ID) AS cnt FROM utQ q LEFT JOIN utb b ON q.Q_ID = b.B_Q_ID
)
SELECT CAST(sumb/cnt AS decimal(5,2)) FROM all_results ar
/* 92
Get all white squares that have been painted only with spray cans empty at present.
Output the square names. 
*/
WITH results AS
(
	SELECT b.B_Q_ID, SUM(b.B_VOL) OVER(PARTITION BY b.B_Q_ID) AS sum_q, b.B_V_ID, SUM(b.B_VOL) OVER (PARTITION BY b.B_V_ID) AS sum_v FROM utB b
)
SELECT q.q_name FROM results r JOIN utQ q ON r.B_Q_ID = q.Q_ID
GROUP BY r.B_Q_ID, q.Q_NAME
HAVING MIN(r.sum_q) = 765 AND MIN(r.sum_v) = 255
/* 93
For each airline that transported passengers calculate the total flight duration of its planes.
Result set: company name, duration in minutes. 
*/
Select c.name, sum(x.summ)
FROM company c INNER JOIN trip t on t.id_comp = c.id_comp
INNER JOIN (select distinct trip_no, date from pass_in_trip) pit ON t.trip_no = pit.trip_no
CROSS APPLY (
   VALUES(
      CASE WHEN t.time_out < t.time_in THEN DATEDIFF(MINUTE, t.time_out, t.time_in)
   ELSE 1440 - abs(DATEDIFF(MINUTE, t.time_out, t.time_in))
   END 
   )
) as x(summ)
group by c.name
/* 94
For seven successive days starting with the earliest date when the number of departures from Rostov was maximal, get the number of flights departed from Rostov.
Result set: date, number of flights. 
*/
with nums1 as  (select 1 as n from (VALUES(1), (1)) as t(n)),
nums2 as  (select 1 as n from nums1 n1 cross join nums1 n2),
nums3 as (select 1 as n from nums2 n2 cross join nums2 n3),
rn as (select row_number() over(order by (select null)) as rownum from nums3),
ranks as (
	select date from (
			select date, row_number() over(order by count(distinct t.trip_no) desc, date asc) as rw 
			from trip t inner join pass_in_trip pit on t.trip_no = pit.trip_no
			where t.town_from = 'Rostov'
			group by date
	) as dt
	where dt.rw = 1
), dt_range as
(
  select dateadd(day, rn.rownum - 1, r.date) as date
  from ranks r inner join rn rn on rn.rownum < 8
)
select dtr.date, count(distinct t.trip_no) from
trip t inner join pass_in_trip pit on t.trip_no = pit.trip_no
and t.town_from = 'Rostov'
right join dt_range dtr on dtr.date = pit.date
group by dtr.date;

/* 95
Using the Pass_in_Trip table, calculate for each airline:
1) the number of performed flights;
2) the number of plane types used;
3) the number of different passengers that have been transported;
4) the total number of passengers that have been transported by the company.
Output: airline name, 1), 2), 3), 4). 
*/
WITH almost_all_aggrs AS
(
	SELECT c.ID_comp, c.name,  COUNT(distinct t.plane) AS planes, COUNT(DISTINCT pit.ID_psg) as diff_psgs, COUNT(pit.id_psg) AS tot_psgs FROM Company c JOIN  (
			Trip t JOIN Pass_in_trip pit ON t.trip_no = pit.trip_no
		)
		ON c.ID_comp = t.ID_comp
	GROUP BY c.ID_comp, c.name
)
SELECT aag.name,
(
	SELECT SUM(d.num_flights) FROM (
		SELECT DISTINCT t.ID_comp, t.trip_no, (
			SELECT COUNT(DISTINCT pit2.date) FROM Pass_in_trip pit2 
			WHERE pit2.trip_no = t.trip_no
		) AS num_flights from Trip t JOIN Pass_in_trip pit ON t.trip_no = pit.trip_no
	) AS d WHERE d.ID_comp = aag.ID_comp
),
aag.planes, aag.diff_psgs, aag.tot_psgs FROM almost_all_aggrs aag
/* 96
Considering only red spray cans used more than once, get those that painted squares currently having a non-zero blue component.
Result set: spray can name. 
*/
WITH aggs AS 
(
	select v.V_ID, v.V_NAME from utV v JOIN utB b ON v.V_ID = b.B_V_ID
	WHERE v.V_COLOR = 'R'
	GROUP BY v.V_ID, v.V_NAME
	HAVING COUNT(*) >= 2
), results AS
(
	select * from aggs v JOIN utB b ON v.V_ID = b.B_V_ID
	WHERE EXISTS
		(
			SELECT 1/0 FROM utB b2 JOIN utV v2 ON b2.B_V_ID = v2.V_ID
				WHERE b.B_Q_ID = b2.B_Q_ID AND v2.V_COLOR = 'B'
		)
)SELECT r.V_NAME FROM results r
GROUP BY r.V_NAME

/* 97
From the Laptop table, select rows fulfilling the following condition:
the values of the speed, ram, price, and screen columns can be arranged in such a way that each successive value exceeds two or more times the previous one.
Note: all known laptop characteristics are greater than zero.
Output: code, speed, ram, price, screen. 
*/
WITH not_null_data AS
(
	SELECT * FROM Laptop l
	WHERE l.price IS NOT NULL
), pivoted_data AS
(
	SELECT l.code, unpiv.name, unpiv.value,
	CASE 
		WHEN CAST(unpiv.value AS MONEY) * 2 > LEAD(CAST(unpiv.value AS MONEY), 1, CAST(unpiv.value AS MONEY) * 2) OVER(PARTITION BY l.code ORDER BY CAST(unpiv.value AS MONEY)) 
		THEN 1
		ELSE 0
	END AS flag
	FROM not_null_data l
	CROSS APPLY (
		VALUES
		('speed', CAST(l.speed AS varchar(50))), 
		('ram', CAST(l.ram AS varchar(50))), 
		('price', CAST(l.price AS varchar(50))), 
		('screen', CAST(l.screen AS varchar(50))
		)
	) AS unpiv(name, value)
), valid_data AS 
(
	SELECT pd.code FROM pivoted_data pd
	GROUP BY pd.code
	HAVING MAX(pd.flag) = 0
)
SELECT l.code, l.speed, l.ram, l.price, l.screen FROM valid_data pd
JOIN Laptop l ON pd.code = l.code
/* 98
Display the list of PCs, for each of which the result of the bitwise OR operation performed on the binary representations of its respective processor speed and RAM capacity contains a sequence of at least four consecutive bits set to 1.
Result set: PC code, processor speed, RAM capacity. 
*/
WITH cte AS
(
	SELECT 1 AS bit1, MAX(pc.speed | pc.ram) AS bitwise_or FROM PC pc
	UNION ALL
	SELECT c.bit1 * 2, c.bitwise_or FROM cte c
	WHERE c.bit1 * 2 <= c.bitwise_or
), zeroes_ones AS
(
SELECT pc.code, pc.speed, pc.ram, c.bit1, pc.speed | pc.ram AS bitwise, CAST(CAST((pc.speed | pc.ram) & bit1 AS bit) AS char(1)) AS res  FROM cte c JOIN PC pc ON c.bit1 <= (pc.speed | pc.ram)
), aggs AS
(
	SELECT zo.code, STRING_AGG(zo.res, '') WITHIN GROUP (ORDER BY zo.bit1) AS res FROM zeroes_ones zo
	GROUP BY zo.code
)
SELECT pc.code, pc.speed, pc.ram FROM aggs a
JOIN PC pc ON a.code = pc.code
WHERE PATINDEX('%1111%', a.res) <> 0
/* 99
Only Income_o and Outcome_o tables are considered. It is known that no money transactions are performed on Sundays.
For each buy-back center (point) and each funds receipt date, determine the encashment date according to the following rules:
1. The encashment date is the same as the receipt date if there is no payment entry in the Outcome_o table for this date and point.
2. Otherwise, the first possible date after the receipt date is used that doesn�t fall on Sunday and doesn�t have a corresponding payment entry in the Outcome_o table for the point in question.
Output: point, receipt date, encashment date. 
*/

/* 100
Write a query that displays all operations from the Income and Outcome tables as follows:
date, sequential record number for this date, buy-back center receiving funds, funds received, buy-back center making a payment, payment amount.
All revenue transactions for all centers made during a single day are ordered by the code field, and so are all expense transactions.
If the numbers of revenue and expense transactions are different for a day, display NULL in the corresponding columns for missing operations. 
*/
WITH cte_inc AS
(
	SELECT code, point, [date], inc, row_number() OVER(PARTITION BY [date] ORDER BY code) AS rn_ci FROM INCOME
), cte_out AS
(
	SELECT code, point, [date], out, row_number() OVER(PARTITION BY [date] ORDER BY code) AS rn_co FROM OUTCOME
)
SELECT ISNULL(ci.date, co.date) AS [date], COALESCE(ci.rn_ci, co.rn_co) ,  ci.point as point_i, ci.inc,   co.point as point_o, co.out
FROM cte_inc ci FULL OUTER JOIN cte_out co ON ci.[date] = co.[date] AND ci.rn_ci = co.rn_co