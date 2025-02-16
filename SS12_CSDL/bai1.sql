CREATE DATABASE ss12;
USE ss12;

-- Tạo bảng orders
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    quantity INT DEFAULT 1,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    order_date DATE NOT NULL
);

-- Thêm dữ liệu vào bảng
INSERT INTO orders (customer_name, product, quantity, price, order_date) VALUES
('Alice', 'Laptop', 2, 1500.00, '2023-01-10'),
('Bob', 'Smartphone', 5, 800.00, '2023-02-15'),
('Carol', 'Laptop', 1, 1500.00, '2023-03-05'),
('Alice', 'Keyboard', 3, 100.00, '2023-01-20'),
('Dave', 'Monitor', NULL, 300.00, '2023-04-10');

DELIMITER &&
create trigger before_insert_orders
before insert on orders
for each row 
begin 
	if new.quantity is null or new.quantity < 1 then 
		set new.quantity = 1;
	end if;
    
	if new.order_date is null then
		set new.order_date = curdate();
    end if;
end &&
DELIMITER &&
INSERT INTO orders (customer_name, product, quantity, price, order_date) 
VALUES 
    ('Anna', 'Tablet', NULL, 400.00, NULL),
    ('John', 'Mouse', -3, 50.00, '2023-05-01');

select * from orders
drop trigger if exists before_insert_orders;