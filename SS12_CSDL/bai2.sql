USE ss12;
create table price_changes(
	change_id int primary key auto_increment,
    product varchar(255),
    old_price decimal(10,2),
    new_price decimal(10,2)
);

DELIMITER &&
create trigger after_update_price
after update on orders
for each row
begin
	if old.price <> new.price then
		INSERT INTO price_changes (change_id,product, old_price, new_price)
        VALUES (OLD.order_id,OLD.product, OLD.price, NEW.price);
	end if;
end &&
DELIMITER &&

UPDATE orders SET price = 1400.00 WHERE product = 'Laptop';

UPDATE orders SET price = 1000.00 WHERE product = 'Smartphone';

SELECT * FROM price_changes;
SELECT * FROM orders;
 drop trigger after_update_price