CREATE TABLE goldusers_signup(userid integer,gold_signup_date date);

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--01 - What is the total amount each customer spent on zomato?

select a.userid,sum(b.price) from sales a inner join product b on a.product_id = b.product_id
group by a.userid;

--02 - How many days has each customer visited zomato?

select userid,count(created_date) as distinct_days from sales group by  userid;

--03 - What was the first product purchased by each customer?

select *from
(select *,rank() over (partition by userid order by created_date) rnk from sales)a where rnk=1;

-- 04 - What is the most purchased item on the menu and how many times was it purchased by all customer?

select  userid,count(product_id)cnt from sales where product_id=
(select top 1 product_id/*,count(product_id) cnt*/ from sales group by product_id order by count(product_id)desc)
group by userid;

-- 05 - Which item was the most popular for each customer?

select *from
(select *,rank() over (partition by userid order by cnt desc)rnk from
(select userid,product_id,count(product_id)cnt from sales group by userid,product_id)a)b
where rnk = 1;

--06 - Which item was purshed first by the customer after they became a member?

select *from
(select c.*,rank () over (partition by userid order by created_date) rnk from
(select a.userid, a.created_date , a.product_id, b.gold_signup_date
from sales a inner join goldusers_signup b on a.userid=b.userid
and created_date >=gold_signup_date)c )b where rnk = 1;

-- 07 - Which item was purchased just before the customer became a member ?

select *from
(select c.*,rank () over (partition by userid order by created_date desc) rnk from
(select a.userid, a.created_date , a.product_id, b.gold_signup_date
from sales a inner join goldusers_signup b on a.userid=b.userid
and created_date <=gold_signup_date)c )b where rnk = 1;

-- 08 - What is the total orders and amount spent for each member before they became a member?

select userid,count(created_date) order_purchased,sum(price) total_amt_spent from 
(select c.*,d.price from 
(select a.userid, a.created_date , a.product_id, b.gold_signup_date
from sales a inner join goldusers_signup b on a.userid=b.userid
and created_date <=gold_signup_date)c inner join product d on c.product_id = d.product_id)o
group by userid;

--09 - If buying each product generates points for eg 5rs=2 zomato point and each product has different
--     purchasing points for eg for p1 5rs = 1 zomato point ,for p2 10rs= 5 zomato point and p3 5rs=1 zomato point?

--calculate points collected by each customer and for which product most points have been given till now.

select userid , sum(total_points)*2.5 total_money_earned from (
select o.*,amt/points total_points from
(select d.*,case 
when product_id=1 then 5 
when product_id=2 then 2 
when product_id=3 then 5 else 0 end as points from
(select c.userid ,c.product_id,sum(price) amt from
(select  a.*,b.price from sales a inner join product b on a.product_id=b.product_id)c
group by userid ,product_id)d)o)f 
group by userid;

select * from
(select *,rank () over (order by total_points_earned desc ) rnk from
(select product_id , sum(total_points) total_points_earned from 
(select o.*,amt/points total_points from
(select d.*,case 
when product_id=1 then 5 
when product_id=2 then 2 
when product_id=3 then 5 else 0 end as points from
(select c.userid ,c.product_id,sum(price) amt from
(select  a.*,b.price from sales a inner join product b on a.product_id=b.product_id)c
group by userid ,product_id)d)o)f group by product_id)f)g where rnk = 1  ;

-- 10 - In the first one year after a customer joins the gold program (including their join date) irrespective
--      of what the customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3 and 
--      what was their points earnings in thier first yr?

-- 1 ZP = 2rs
-- 0.5 ZP = 1rs

select c.*,d.price*0.5 total_points_earned from
(select a.userid, a.created_date , a.product_id, b.gold_signup_date
from sales a inner join goldusers_signup b on a.userid=b.userid
and created_date >=gold_signup_date and created_date < = DATEADD(YEAR,2, gold_signup_date))c
inner join product d on c.product_id = d.product_id;

-- 11 - rnk all the transaction of the customer?

select *,rank () over (partition by userid  order by created_date )rnk 
from sales;

--12 - rank all the transaction for each member whenever they are a zomato gold member frof every non gold member transcation mark as NA ?

select e.*, case when rnk =0 then 'NA' else rnk end as rnkk from  
(select c.*,cast((case when gold_signup_date is null then 0 else rank() over (partition by userid order by created_date desc )end ) as varchar) as  rnk from
(select a.userid, a.created_date , a.product_id, b.gold_signup_date
from sales a left join goldusers_signup b on a.userid=b.userid
and created_date >=gold_signup_date )c)e;



drop table if exists emp_attendance;
create table emp_attendance
(
	employee 	varchar(10),
	dates 		date,
	status 		varchar(20)
);
insert into emp_attendance values('A1', '2024-01-01', 'PRESENT');
insert into emp_attendance values('A1', '2024-01-02', 'PRESENT');
insert into emp_attendance values('A1', '2024-01-03', 'PRESENT');
insert into emp_attendance values('A1', '2024-01-04', 'ABSENT');
insert into emp_attendance values('A1', '2024-01-05', 'PRESENT');
insert into emp_attendance values('A1', '2024-01-06', 'PRESENT');
insert into emp_attendance values('A1', '2024-01-07', 'ABSENT');
insert into emp_attendance values('A1', '2024-01-08', 'ABSENT');
insert into emp_attendance values('A1', '2024-01-09', 'ABSENT');
insert into emp_attendance values('A1', '2024-01-010', 'PRESENT');
insert into emp_attendance values('A2', '2024-01-06', 'PRESENT');
insert into emp_attendance values('A2', '2024-01-07', 'PRESENT');
insert into emp_attendance values('A2', '2024-01-08', 'ABSENT');
insert into emp_attendance values('A2', '2024-01-09', 'PRESENT');
insert into emp_attendance values('A2', '2024-01-010', 'ABSENT');

SELECT * from emp_attendance;


with cte as 
		(select *, row_number() over(partition by employee order by employee, dates) as rn 
		from emp_attendance),
	cte_present as
		(select *, row_number() over(partition by employee order by employee, dates)
		, rn - row_number() over(partition by employee order by employee, dates) as flag
		from cte where status='PRESENT' ),
	cte_absent as
		(select *, row_number() over(partition by employee order by employee, dates)
		, rn - row_number() over(partition by employee order by employee, dates) as flag
		from cte where status='ABSENT' )
select employee 
, first_value(dates) over(partition by employee, flag order by employee, dates) as from_date 
, last_value(dates) over(partition by employee, flag order by employee, dates
						range between unbounded preceding and unbounded following) as to_date 
, status						
from cte_present
union 
select  employee 
, first_value(dates) over(partition by employee, flag order by employee, dates) as from_date 
, last_value(dates) over(partition by employee, flag order by employee, dates
						range between unbounded preceding and unbounded following) as to_date 
, status						
from cte_absent
order by employee, from_date