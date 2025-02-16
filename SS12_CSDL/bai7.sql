CREATE DATABASE ss10_7;

USE ss10_7;

CREATE TABLE departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(255),
    manager VARCHAR(255),
    budget DECIMAL(15, 2)
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255),
    dept_id INT,
    salary DECIMAL(15, 2),
    hire_date DATE,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY AUTO_INCREMENT,
    project_name VARCHAR(255),
    dept_id INT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(255),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE project_employees (
    project_id INT,
    employee_id INT,
    FOREIGN KEY (project_id) REFERENCES projects(project_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    PRIMARY KEY (project_id, employee_id) 
);

CREATE TABLE project_warnings (
    warning_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT,
    warning_message VARCHAR(255),
    warning_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

CREATE TABLE dept_warnings (
    warning_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_id INT,
    warning_message VARCHAR(255),
    warning_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
--
DELIMITER //

CREATE TRIGGER before_employee_insert
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    -- Kiểm tra lương nhân viên
    IF NEW.salary < 500 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lương nhân viên phải lớn hơn hoặc bằng 500';
    END IF;

    -- Kiểm tra phòng ban tồn tại
    IF NOT EXISTS (SELECT 1 FROM departments WHERE dept_id = NEW.dept_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng ban không tồn tại';
    END IF;

    -- Kiểm tra tất cả dự án trong phòng ban đã hoàn thành chưa
    IF (SELECT COUNT(*) FROM projects WHERE dept_id = NEW.dept_id AND status != 'Completed') = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không thể thêm nhân viên vào phòng ban có tất cả dự án đã hoàn thành';
    END IF;
END //

DELIMITER ;
--
drop trigger before_employee_insert
DELIMITER //

CREATE TRIGGER after_project_update
AFTER UPDATE ON projects
FOR EACH ROW
BEGIN
    -- Nếu trạng thái là "Delayed", ghi cảnh báo
    IF NEW.status = 'Delayed' THEN
        INSERT INTO project_warnings (project_id, warning_message)
        VALUES (NEW.project_id, 'Dự án bị hoãn');
    END IF;

    -- Nếu trạng thái là "Completed", cập nhật ngày kết thúc và kiểm tra ngân sách
    IF NEW.status = 'Completed' THEN
        UPDATE projects SET end_date = NOW() WHERE project_id = NEW.project_id;

        -- Kiểm tra tổng lương nhân viên của phòng ban
        SET @total_salary = (SELECT SUM(salary) FROM employees WHERE dept_id = NEW.dept_id);
        SET @budget = (SELECT budget FROM departments WHERE dept_id = NEW.dept_id);

        -- Nếu vượt ngân sách, ghi cảnh báo
        IF @total_salary > @budget THEN
            INSERT INTO dept_warnings (dept_id, warning_message)
            VALUES (NEW.dept_id, 'Vượt quá ngân sách phòng ban');
        END IF;
    END IF;
END //

DELIMITER ;
--
CREATE VIEW FullOverview AS
SELECT
    e.employee_id,
    e.name AS employee_name,
    d.dept_name,
    CONCAT('$', e.salary) AS salary,
    e.hire_date,
    p.project_name,
    p.status AS project_status
FROM
    employees e
JOIN
    departments d ON e.dept_id = d.dept_id
LEFT JOIN
    project_employees pe ON e.employee_id = pe.employee_id
LEFT JOIN
    projects p ON pe.project_id = p.project_id;
--
INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Alice', 1, 400, '2023-07-01');

INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Bob', 999, 1000, '2023-07-01');

INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Charlie', 2, 1500, '2023-07-01');

INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('David', 1, 2000, '2023-07-01');
---
UPDATE projects SET status = 'Delayed' WHERE project_id = 1;

UPDATE projects SET status = 'Completed', end_date = NULL WHERE project_id = 2;

UPDATE projects SET status = 'Completed' WHERE project_id = 3;

UPDATE projects SET status = 'In Progress' WHERE project_id = 4;
--
SELECT * FROM FullOverview;
INSERT INTO departments (dept_name, manager, budget) VALUES
('Sales', 'John Smith', 100000),
('Marketing', 'Jane Doe', 50000),
('Engineering', 'David Lee', 200000);

INSERT INTO employees (name, dept_id, salary, hire_date) VALUES
('Alice', 1, 600, '2023-01-01'),
('Bob', 1, 1200, '2023-02-01'),
('Charlie', 2, 800, '2023-03-01');

INSERT INTO projects (project_name, dept_id, start_date, status) VALUES
('Project A', 1, '2023-01-01', 'In Progress'),
('Project B', 1, '2023-02-01', 'Completed'),
('Project C', 2, '2023-03-01', 'In Progress');

INSERT INTO project_employees (project_id, employee_id) VALUES
(1, 1),
(1, 2),
(3, 3);