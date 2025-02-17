CREATE DATABASE ss10_8;
USE ss10_8;
CREATE TABLE departments (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    manager VARCHAR(100) NOT NULL,
    budget DECIMAL(15, 2) NOT NULL
);
CREATE TABLE employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    dept_id INT,
    salary DECIMAL(10, 2) NOT NULL,
    hire_date DATE NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    emp_id INT,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    status VARCHAR(50) NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);
CREATE TABLE salary_history (
    salary_history_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    old_salary DECIMAL(10, 2),
    new_salary DECIMAL(10, 2),
    effective_date DATE,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);
CREATE TABLE salary_warnings (
    warning_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    warning_message VARCHAR(255),
    warning_date DATE,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);
-- cau 4
DELIMITER //

CREATE TRIGGER after_salary_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    -- Ghi lại lịch sử thay đổi lương
    INSERT INTO salary_history (emp_id, old_salary, new_salary, effective_date)
    VALUES (NEW.emp_id, OLD.salary, NEW.salary, CURDATE());

    -- Kiểm tra nếu lương giảm quá 30%
    IF NEW.salary < OLD.salary * 0.7 THEN
        INSERT INTO salary_warnings (emp_id, warning_message, warning_date)
        VALUES (NEW.emp_id, 'Salary decreased by more than 30%', CURDATE());
    END IF;

    -- Kiểm tra nếu lương tăng vượt 150%
    IF NEW.salary > OLD.salary * 1.5 THEN
        UPDATE employees SET salary = OLD.salary * 1.5 WHERE emp_id = NEW.emp_id;
        INSERT INTO salary_warnings (emp_id, warning_message, warning_date)
        VALUES (NEW.emp_id, 'Salary increased above allowed threshold (adjusted to 150% of previous salary)', CURDATE());
    END IF;
END //

DELIMITER ;
-- cau 5
DELIMITER //

CREATE TRIGGER after_project_insert
AFTER INSERT ON projects
FOR EACH ROW
BEGIN
    -- Kiểm tra số lượng dự án đang hoạt động của nhân viên
    DECLARE active_projects INT;
    SELECT COUNT(*) INTO active_projects
    FROM projects
    WHERE emp_id = NEW.emp_id AND status = 'In Progress';

    IF active_projects > 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee is already involved in more than 3 active projects.';
    END IF;

    -- Kiểm tra ngày bắt đầu dự án
    IF NEW.status = 'In Progress' AND NEW.start_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Project start date cannot be in the future for "In Progress" projects.';
    END IF;
END //

DELIMITER ;
-- cau 6
drop view PerformanceOverview;
create view performanceoverview as
select 
    p.project_id,
    p.project_name,
    count(e.emp_id) as employee_count,
    datediff(p.end_date, p.start_date) as total_days,
    p.status
from projects p
left join employees e on p.emp_id = e.emp_id
group by p.project_id, p.project_name, p.start_date, p.end_date, p.status;
-- cau 7
-- Trường hợp 1: Lương giảm hơn 30%
UPDATE employees SET salary = salary * 0.5 WHERE emp_id = 1;

-- Trường hợp 2: Lương tăng vượt 150%

UPDATE employees SET salary = salary * 2 WHERE emp_id = 2;
-- cau 8
-- Trường hợp 1: Nhân viên tham gia hơn 3 dự án
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 1', 1, CURDATE(), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 2', 1, CURDATE(), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 3', 1, CURDATE(), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('New Project 4', 1, CURDATE(), 'In Progress');

-- Trường hợp 2: Ngày bắt đầu dự án không hợp lệ
INSERT INTO projects (name, emp_id, start_date, status) VALUES ('Future Project', 2, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'In Progress');
-- cau 9
SELECT * FROM PerformanceOverview;
SELECT * FROM salary_history;
SELECT * FROM salary_warnings;