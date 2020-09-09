drop database if exists webshop;
CREATE DATABASE webshop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

use webshop;

create table user(
     id			int not null primary key auto_increment,
     name 	    varchar(255),
     surname 	varchar(255),
     email      varchar(255),
     address	varchar(255) not null,
     contact	varchar(20) not null,
     sessionID  varchar(255)
);

CREATE TABLE category (
      id  int not null primary key auto_increment,
      name varchar(255)
);

CREATE TABLE product (
    id 		    int NOT null primary key AUTO_INCREMENT,
    name 		varchar(255) NOT NULL,
    category  	int not null,
    price 	    decimal(10,2) NOT NULL DEFAULT '0.00',
    foreign key (category) references category(id) ON DELETE CASCADE
);

CREATE TABLE cart (
      id 			int NOT null primary key AUTO_INCREMENT,
      sessionID		varchar(255),
      price			decimal(10,2) default 0.00,
      ordered       tinyint default 0
);

create table orders (
    id 		    int NOT null primary key AUTO_INCREMENT,
    user 	    int not null,
    cart	    int not null,
    time        datetime default now(),
    delivered      tinyint(2) default 0,
    foreign key (user) references user(id) ON DELETE CASCADE,
    foreign key (cart) references cart(id) ON DELETE CASCADE
);

CREATE TABLE product_cart (
     id 		int NOT null primary key AUTO_INCREMENT,
     cartID     int(11) NOT null,
     productID  int(11) NOT null,
     amount     int(11) NOT null default 1,
     foreign key (cartID) references cart (id) ON DELETE CASCADE,
     foreign key (productID) references product (id) ON DELETE CASCADE
);

### TRIGGER ###
# 1. Create cart for user after registration
CREATE TRIGGER new_user
AFTER INSERT ON user
FOR EACH ROW
INSERT INTO cart(sessionID) value (new.sessionID);

# 2. Calculate new price for cart after adding new product into it (price*amount)
CREATE TRIGGER calculate_price
AFTER INSERT
ON product_cart
FOR EACH ROW
UPDATE cart set  price = price + NEW.amount*(
        select p.price from product p
        inner join product_cart pc on p.id = pc.productID
        where pc.id = NEW.id
    )
WHERE cart.id=NEW.cartID;

insert into user (name, surname, email, address, contact, sessionID) VALUES
('Matej', 'Malčić', 'matej.malcic3@gmail.com', 'Sjnjak 10', '0997580863', 'f8923uf9hv927z'),
('David', 'Berić', 'dberic@gmail.com', 'Istarska 15', '0995437351', 'f7as8f6a78a7'),
('Test', 'Testić', 'testergmail.com', 'Vukovarska 125', '0995431321', 'fca87fa8a8f9a');

insert into category (name) values
('Electronic'),
('Clothes'),
('Footwear'),
('Toys');

insert into product (name, category, price) VALUES
('Lenovo G580 laptop', '1', '2099.99'),
('Playstation 4', '1', '2599.99'),
('Nike T-Shirt', '2', '199.99'),
('Adidas 100S', '3', '699.99'),
('Nike Cortez', '3', '599.99'),
('Teddy Bear', '4', '99.99'),
('Rubik Cube', '4', '49.99');

insert into product_cart (cartID, productID, amount) VALUES
(1,1,1),
(1,2,1),
(2,3,2),
(2,4,1),
(2,6,1),
(3,1,1),
(3,7,1);

insert into orders (user, cart) VALUES
(1,2),
(2,3);

### UPDATE ###
UPDATE cart SET ordered=1 WHERE id IN (2,3);
#
UPDATE user SET name='Marko', surname='Golić' WHERE name='Test';
#
UPDATE orders SET delivered=1 WHERE id =1;
#
UPDATE product SET price = rand()*100
WHERE category = 4;
#
UPDATE product_cart SET amount = FLOOR(RAND()*4+1)
WHERE productID NOT IN(
    select p.id from product p
    inner join category c on p.category = c.id
    where c.name = 'Electronic'
);

### SELECT ###
# 1. Select carts that are not ordered yet
select * from cart where ordered = 0;

# 2. Select first and last name from user who is currently waiting his order
select u.name, u.surname from user u
left join orders o on u.id = o.user
where o.delivered = 0;

# 3. How many products cost less then 300
select count(id) from product where price < 300;

# 4. Print average price of all orders
select avg(c.price) from orders o
inner join cart c on o.cart = c.id;

# 5. Select product name, category and price that have Nike in name
select p.name, c.name, p.price from product p
inner join category c on p.category = c.id
where p.name like '%Nike%';

# 6. Select users whose order price is over 2000.00
select concat(u.name, ' ', u.surname) from user u
inner join orders o on u.id = o.user
inner join cart c on o.cart = c.id
where c.price > 2000.00;

# 7. Select products name, category name and price that are in cart waiting for order
SELECT p.name, cat.name, p.price FROM product p
inner join category cat on cat.id = p.category
inner join product_cart pc on p.id = pc.productID
inner join cart c on pc.cartID = c.id
where c.ordered = 0;

# 8. Select all products that are ordered today
select p.name, p.price from product p
left join product_cart pc on p.id = pc.productID
inner join cart c on pc.cartID = c.id
right join orders o on c.id = o.cart
where day(o.time) = day(now());

# 9. Group products by category from most expensive
SELECT c.name, AVG(p.price) FROM product p
INNER JOIN category c on p.category = c.id
GROUP BY p.category ORDER BY AVG(p.price) DESC;

# 10. Select users that have ordered 4 or more products
select concat(u.name, ' ', u.surname), SUM(pc.amount) as total_products from user u
left join orders o on u.id = o.user
inner join cart c on o.cart = c.id
inner join product_cart pc on c.id = pc.cartID
group by u.id
having total_products >= 4;


### DELETE ###
DELETE FROM product WHERE category = 3
ORDER BY price LIMIT 1;
#
DELETE FROM  user WHERE length(contact)<5;
#
DELETE p FROM  product p
INNER JOIN category c on p.category = c.id
WHERE p.category NOT IN (c.id); #useless delete because i have category int not null in create table product
#
DELETE FROM product WHERE price < 10;
#
DELETE FROM user WHERE email NOT LIKE '%@%';
