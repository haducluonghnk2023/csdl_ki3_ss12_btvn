create table deleted_orders (
	delete_id int primary key auto_increment,
    order_id int not null,
    customer_name varchar(100) not null,
    product varchar(100) not null,
    order_date date not null,
    delete_at datetime not null,
    foreign key (order_id) references orders(order_id)
);

DELIMITER &&
create trigger after_delete_order
after delete on orders
for each row
begin 
	insert into deleted_orders(order_id,customer_name,product,order_date,delete_at) 
    values (old.order_id,old.customer_name,old.product,old.order_date,now());
end &&
DELIMITER &&
drop trigger after_delete_order;

-- SELECT TABLE_NAME, CONSTRAINT_NAME 
-- FROM information_schema.KEY_COLUMN_USAGE 
-- WHERE TABLE_NAME = 'deleted_orders' 
-- AND REFERENCED_TABLE_NAME = 'orders';
-- ALTER TABLE deleted_orders DROP FOREIGN KEY deleted_orders_ibfk_1;

DELETE FROM orders WHERE order_id = 4;

DELETE FROM orders WHERE order_id = 5;

select * from deleted_orders;