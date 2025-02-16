CREATE TABLE budget_warnings (
    warning_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(project_id),
    warning_message VARCHAR(255) NOT NULL
);

DELIMITER //
DROP TRIGGER IF EXISTS after_insert_worker;
CREATE TRIGGER after_insert_worker
AFTER INSERT ON workers
FOR EACH ROW
BEGIN
    DECLARE total_salary_of_project DECIMAL(10, 2);
	DECLARE project_budget DECIMAL(10,2);
    SELECT SUM(salary) INTO total_salary_of_project
    FROM workers
    WHERE project_id = NEW.project_id;
    SELECT budget INTO project_budget FROM projects WHERE project_id = NEW.project_id;
    -- Kiểm tra nếu tổng lương vượt quá ngân sách
    IF total_salary_of_project > project_budget THEN
        -- Kiểm tra xem cảnh báo đã tồn tại chưa
        IF NOT EXISTS (
            SELECT 1
            FROM budget_warnings
            WHERE project_id = NEW.project_id AND warning_message = "Budget exceeded due to high salary"
        ) THEN
            -- Ghi cảnh báo vào bảng budget_warnings
            INSERT INTO budget_warnings (project_id, warning_message)
            VALUES (NEW.project_id, "Budget exceeded due to high salary");
        END IF;
    END IF;
END //
DELIMITER ;

CREATE VIEW ProjectOverview AS
SELECT
    p.project_id,
    p.name AS project_name,
    p.budget,
    SUM(w.salary) AS total_salary,
    COUNT(w.project_id) AS worker_count
FROM
    projects p
LEFT JOIN
    workers w ON p.project_id = w.project_id
GROUP BY
    p.project_id, p.name, p.budget;

INSERT INTO workers (name, project_id, salary) VALUES ('Michael', 1, 6000.00);
INSERT INTO workers (name, project_id, salary) VALUES ('Sarah', 2, 100000.00);
INSERT INTO workers (name, project_id, salary) VALUES ('David', 3, 1000.00);

-- Kiểm tra kết quả
SELECT * FROM budget_warnings;
SELECT * FROM ProjectOverview;