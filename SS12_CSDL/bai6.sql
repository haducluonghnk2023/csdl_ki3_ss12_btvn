CREATE TABLE budget_warnings (
    warning_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(project_id),
    warning_message VARCHAR(255) NOT NULL
);

delimiter //
create trigger after_update_total_salary
after update on projects
for each row
begin
    if new.total_salary > new.budget then
        if not exists (select 1 from budget_warnings where project_id = new.project_id) then
            insert into budget_warnings (project_id, warning_message)
            values (new.project_id, 'budget exceeded due to high salary');
        end if;
    else
        delete from budget_warnings where project_id = new.project_id;
    end if;
end //
delimiter ;


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