-- Exercise 1 - Computer firm
-- Find the model number, speed and hard drive capacity for all the PCs with prices below $500.


Select model, speed, hd from pc where price < 500

-- Exercise 2 - Computer firm
-- List all printer makers. Result set: maker.

select distinct maker from product where type = 'Printer';


-- Exercise 3 -  Computer firm
-- Find the model number, RAM and screen size of the laptops with prices over $1000. 

select model, ram, screen from laptop where price > 1000

-- Exercise 4 - Computer firm

Select * from printer where color='y';

-- Exercise 5 - Computer firm

Select model, speed, hd from pc
where price < 600 and cd in ('12x', '24x');

-- Exercise 6 - Computer firm
-- For each maker producing laptops with a hard drive capacity of 10 Gb or higher, find the speed of such laptops. Result set: maker, speed.

Select distinct pro.maker, l.speed
from product pro inner join laptop l on l.model = pro.model
where l.hd >= 10

-- Exercise 7 - Computer firm
-- Get the models and prices for all commercially available products (of any type) produced by maker B. 

Select distinct d.model, d.price
from product p
inner join (
select model, price from pc
union all
select model, price from laptop
union all
select model, price from printer
) d on p.model = d.model
where p.maker='B';

-- Exercise 8 - Computer firm
-- Find the makers producing PCs but not laptops. 

select distinct p1.maker from product p1
where not exists
(select null from product p
where p.maker = p1.maker and p.type = 'Laptop')
and exists
(select null from product p where p.maker = p1.maker
and p.type='PC')

-- Exercise 9 - 
-- Find the makers of PCs with a processor speed of 450 MHz or more. Result set: maker.

select maker from product inner join pc on product.model = pc.model where pc.speed >= 450
group by maker


-- Exercise 10 - 
-- Find the printer models having the highest price. Result set: model, price.

Select model, price from printer
where price = (select max(price) from printer)

-- - Exercise 11 - Computer firm

Select avg(speed) from pc

-- Exercise 12 - 

Select avg(speed) from laptop where price > 1000

-- Exercise 13 

Select avg(speed) from product inner join pc on pc.model = product.model where product.maker='A';

-- Exercise 14 - Ships
-- For the ships in the Ships table that have at least 10 guns, get the class, name, and country.

SELECT S.CLASS, s.name, c.country from ships s inner join classes c on s.class = c.class
where c.numguns >= 10

-- Exercise 15 - Computer firm
-- Get hard drive capacities that are identical for two or more PCs

Select hd from pc
group by hd having count(*) >=2;

-- Exercise 16 - 
-- Get pairs of PC models with identical speeds and the same RAM capacity. Each resulting pair should be displayed only once, i.e. (i, j) but not (j, i).
-- Result set: model with the bigger number, model with the smaller number, speed, and RAM. 

select distinct p1.model, p2.model, p1.speed, p1.ram
from pc p1 inner join pc p2 on p1.speed = p2.speed and p1.ram = p2.ram and p1.model > p2.model

-- Exercise 17 - 
-- Get the laptop models that have a speed smaller than the speed of any PC.
-- Result set: type, model, speed. 

Select distinct p.type, l.model, l.speed from laptop l inner join product p on p.model = l.model where l.speed < all(select speed from pc)

-- Exercise 18 
-- Find the makers of the cheapest color printers.

Select distinct p.maker, pr.price from product p
inner join printer pr on p.model = pr.model
where pr.color='y' and pr.price = (select min(price) from printer where color ='y')

-- Exercise 19 - 

Select p.maker, avg(l.screen)
from product p inner join laptop l
on l.model = p.model
group by p.maker

-- Exercise 20 - 

select maker, count(distinct model) from product where type='PC'
group by maker
having count(distinct model) >= 3

-- Exercise 21 - Computer firm

Select p.maker, max(pc.price)
from product p join pc pc on pc.model = p.model
group by p.maker

-- Exercise 22 - Computer firm

Select speed, avg(price) from pc where speed > 600
group by speed

-- Exercise 23 - COmputer firm
-- Get the makers producing both PCs having a speed of 750 MHz or higher and laptops with a speed of 750 MHz or higher. 

select p.maker from product p
join pc pc on p.model = pc.model where pc.speed >= 750
intersect
select p.maker from product p
join laptop l on p.model = l.model where l.speed >= 75

-- Exercise 24 - Computer firm
-- List the models of any type having the highest price of all products present in the database. 

with all_products as
(
 select model, price from pc
union all
select model, price from laptop
union all
select model, price from printer
)
select model from all_products where price
= (select max(price) from all_products)
group by model

-- Exercise 25 - Computer
-- Find the printer makers also producing PCs with the lowest RAM capacity and the highest processor speed of all PCs having the lowest RAM capacity.

Select pro.maker from product pro where 
exists (
   select null from product pro1
   where pro1.maker = pro.maker and pro1.type='Printer'
)
and exists (
   select null from product pro1
   where pro1.maker = pro.maker and pro1.type='PC'
) and pro.model in
(
   select  pc1.model from pc pc1
  where pc1.speed = (select max(speed) from pc where ram = 
(select min(ram) from pc))
 and ram = (select min(ram) from pc)
)
group by pro.maker;

select distinct pro.maker from product pro
where pro.type = 'Printer' and pro.maker in (
   select pro1.maker from product pro1 inner join pc pc
on pro1.model = pc.model where pc.ram = (select min(ram) from pc) and pc.speed = (select max(speed) from pc where ram = (select min(ram) from pc)
)
)

-- The first solution is actually better in terms of performance. We are checking whether specific maker has produced any pc and printer. Then we check if this model is in the list of pc models, which have to fulfill several predicates.

--Exercise 26--
-- Find out the average price of PCs and laptops produced by maker A.

Select avg(price) as price from
(
 select price from product p join pc pc on p.model = pc.model
and p.maker='A' 
union all
 select price from product p join laptop l on p.model = l.model
and p.maker='A'
) as p

-- Exercise 27 -- Computer firm
-- Find out the average hard disk drive capacity of PCs produced by makers who also manufacture printers.

Select pro.maker, avg(hd)
from product pro inner join pc pc on pro.model = pc.model where pro.maker in
(select maker from product where type='PC')
and  pro.maker in (select maker from product where type='Printer')
group by pro.maker

-- Exercise 28 - 
-- Using Product table, find out the number of makers who produce only one model.

with one_model as
(
 select maker, count(*) as cnt from product
group by maker
having count(*) = 1
)
select count(*) from one_model;

-- Exercise 29  - Recycling firm
-- Under the assumption that receipts of money (inc) and payouts (out) are registered not more than once a day for each collection point [i.e. the primary key consists of (point, date)], write a query displaying cash flow data (point, date, income, expense)

select point, date, sum(income), sum(outcome) from
(
select point, date, inc as income, null as outcome from income_o
union all
select point, date, null as income, out as outcome from outcome_o
) as x
group by point, date

-- Exercise 30 - Recycling firm
-- Under the assumption that receipts of money (inc) and payouts (out) are registered not more than once a day for each collection point [i.e. the primary key consists of (point, date)], write a query displaying cash flow data (point, date, income, expense)

select x.point ,x.date, sum(x.outcome) outcome,sum(x.income)income from 
(
select i.point,i.date,null outcome , i.inc income from income i 
union all 
select o.point,o.date,o.out outcome ,null income from outcome o
) x
group by x.point,x.date
order by x.point,x.date

/* 31
For ship classes with a gun caliber of 16 in. or more, display the class and the country. 
*/
Use Ships;
select class, country from classes 
where bore >= 16

/* 32
One of the characteristics of a ship is one-half the cube of the calibre of its main guns (mw).
Determine the average ship mw with an accuracy of two decimal places for each country having ships in the database. 
*/
Select country, round(avg(pw3), 2) from
(
  select country, name, bore, power(bore,3)/2 as pw3 from classes c join ships s on 
s.class = c.class
union
  select country, class, bore, power(bore,3)/2 as pw3 from classes c join outcomes on ship = class
)
group by country
/* 33
Get the ships sunk in the North Atlantic battle.
Result set: ship. 
*/
Use Ships;
select ship from outcomes join battles on name=battle where battle='North Atlantic' and result = 'sunk'
/* 34
In accordance with the Washington Naval Treaty concluded in the beginning of 1922, it was prohibited to build battle ships with a displacement of more than 35 thousand tons.
Get the ships violating this treaty (only consider ships for which the year of launch is known).
List the names of the ships.
*/
Use Ships;
Select s.name from ships s inner join classes c on c.class = s.class where s.launched is not null and s.launched >= 1922 and c.displacement > 35000 and c.type ='bb'
/* 35
Find models in the Product table consisting either of digits only or Latin letters (A-Z, case insensitive) only.
Result set: model, type.
*/

/* 36
List the names of lead ships in the database (including the Outcomes table).
*/
select  x.name
from (
select c.class NAME FROM CLASSES C
JOIN outcomes S ON S.ship= C.CLASS
union
select c.class NAME FROM CLASSES C
JOIN SHIPS S ON S.name= C.CLASS
)x

/* 37
Find classes for which only one ship exists in the database (including the Outcomes table).
*/
WITH classes_ships AS
(
SELECT c.class, o.ship FROM Classes c INNER JOIN Outcomes o ON o.ship = c.class
UNION
SELECT c.class, s.name FROM Classes c INNER JOIN Ships s ON c.class = s.class
)
SELECT cs.class FROM classes_ships cs
GROUP BY cs.class
HAVING COUNT(cs.class) = 1
/* 38
Find countries that ever had classes of both battleships (‘bb’) and cruisers (‘bc’).
*/
Select country from classes where type='bb'
intersect
select country from classes where type='bc'

/* 39
Find the ships that `survived for future battles`; that is, after being damaged in a battle, they participated in another one, which occurred later.
*/
with first_dmg as
(
select t.*, max(t.rn) over(partition by ship) as mx from
(
select ship, battle, "date", result, row_number() over(partition by ship order by "date") as rn
from outcomes inner join battles on name=battle
) t
)
select fd.ship from first_dmg fd where exists
(select null from first_dmg fd1 where fd.ship = fd1.ship
and fd1.result='damaged' and rn <> mx)
group by fd.ship having count(*) > 1;

/* 40
Get the makers who produce only one product type and more than one model. Output: maker, type. 
*/
with type_cnts as
(
 select maker, count(model) as cnt_mod, count(distinct type) as cnt_typ from product
group by maker
having count(model) > 1 and count(distinct type) = 1
)
select t.maker, p.type from type_cnts t inner join product p
on p.maker = t.maker
group by t.maker, p.type

-- No need to join back to Products table:
with type_cnts as
(
 select maker, MAX(type) as [type] ,count(model) as cnt_mod, count(distinct type) as cnt_typ from product
group by maker
having count(model) > 1 and count(distinct type) = 1
)
select t.maker, t.type from type_cnts t


/* 41
For each maker who has models at least in one of the tables PC, Laptop, or Printer, determine the maximum price for his products.
Output: maker; if there are NULL values among the prices for the products of a given maker, display NULL for this maker, otherwise, the maximum price.
*/
with all_prods AS
(
   SELECT MODEL, PRICE FROM PC
   UNION ALL
   SELECT MODEL, PRICE FROM Laptop
   UNION ALL 
   SELECT MODEL, PRICE FROM Printer
), mak_mod AS
(
   SELECT p.maker, ap.price from product p INNER JOIN all_prods ap ON ap.model = p.model
), LIST AS (select maker, CASE WHEN EXISTS (select null from mak_mod mm2
  where mm1.maker = mm2.maker and mm2.price is null)
THEN NULL ELSE mm1.price END as XD
  from mak_mod mm1
) select maker, max(XD) from list
group by maker
/* 42
Find the names of ships sunk at battles, along with the names of the corresponding battles.
*/
Select o.ship, b.name from outcomes o left outer join battles b on o.battle = b.name where o.result = 'sunk'
/*
43
Get the battles that occurred in years when no ships were launched into water.
*/
-- This one is actually viable in Oracle SQL
select name from battles where trunc("date", 'YYYY') not in (select trunc(to_date(coalesce(launched, 9999), 'YYYY'), 'YYYY') from ships)
-- This one in MS SQL
select name from battles where datepart(year, [date]) not in (select launched from ships where launched is not null)


/* 44
Find all ship names beginning with the letter R.
*/
select name from ships where name like 'R%'
union
select ship from outcomes where ship like 'R%'
/* 45
Find all ship names consisting of three or more words (e.g., King George V).
Consider the words in ship names to be separated by single spaces, and the ship names to have no leading or trailing spaces. 
*/
select name from ships where name like '% % %'
union
select ship from outcomes where ship like '% % %'

/* 46
For each ship that participated in the Battle of Guadalcanal, get its name, displacement, and the number of guns. 
*/
select distinct o.ship, t.displacement, t.numGuns from outcomes o left join (
 select c.class, c.displacement, c.numGuns, s.name from classes c inner join ships s on s.class = c.class
) t on o.ship = t.name or o.ship = t.class
where o.battle = 'Guadalcanal';
/* 47
Find the countries that have lost all their ships in battles.
*/
WITH all_ships AS
(
	SELECT s.name, c.country FROM Classes c JOIN Ships s ON c.class = s.class
	UNION
	Select c.class, c.country FROM Classes c JOIN Outcomes o ON c.class = o.ship
)
SELECT als.country FROM all_ships AS als
LEFT JOIN (SELECT ship, result FROM Outcomes WHERE result = 'sunk'
) AS o ON als.name = o.ship
GROUP BY als.country
HAVING COUNT(als.name) = COUNT(o.result)


/* 48
Find the ship classes having at least one ship sunk in battles. 
*/
Select s.class from ships s
where exists
(
   select 1 from outcomes o where o.ship = s.name
   and o.result = 'sunk'
)
union
select c.class from classes c inner join outcomes o on o.ship = c.class
where o.result = 'sunk'

/* 49
Find the names of the ships having a gun caliber of 16 inches (including ships in the Outcomes table). 
*/
Select s.name from ships s join classes c on s.class = c.class
where bore = 16
union
select class from classes c inner join outcomes o on o.ship = c.class where bore = 16

/* 50
Find the battles in which Kongo-class ships from the Ships table were engaged. 
*/
select distinct o.battle from ships s inner join outcomes o on s.name = o.ship where s.class = 'Kongo';
/* Need to consider a case, when one ship can participate in many battles */