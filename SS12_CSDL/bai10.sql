CREATE DATABASE ss10_9;
USE ss10_9;
-- cau 2
DELIMITER //
CREATE PROCEDURE GetDoctorDetails (
    IN input_doctor_id INT
)
BEGIN
    SELECT 
        d.doctor_name,
        d.specialization,
        COUNT(DISTINCT a.patient_id) AS total_patients,
        SUM(d.salary) AS total_revenue, 
        COUNT(p.prescription_id) AS total_medicines_prescribed
    FROM doctors d
    LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
    LEFT JOIN prescriptions p ON a.appointment_id = p.appointment_id
    WHERE d.doctor_id = input_doctor_id
    GROUP BY d.doctor_id, d.doctor_name, d.specialization;
END //
DELIMITER ;
drop PROCEDURE GetDoctorDetails;
-- cau 3
CREATE TABLE cancellation_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    log_message VARCHAR(255),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);
-- cau 4
CREATE TABLE appointment_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    log_message VARCHAR(255),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);
-- cau 5
DELIMITER //

CREATE TRIGGER after_appointment_delete
AFTER DELETE ON appointments
FOR EACH ROW
BEGIN
    -- Xóa các đơn thuốc liên quan đến cuộc hẹn đã bị xóa
    DELETE FROM prescriptions WHERE appointment_id = OLD.appointment_id;

    -- Ghi log hủy hẹn hoặc hoàn thành
    IF OLD.status = 'Cancelled' THEN
        INSERT INTO cancellation_logs (appointment_id, log_message)
        VALUES (OLD.appointment_id, 'Cancelled appointment was deleted');
    ELSEIF OLD.status = 'Completed' THEN
        INSERT INTO appointment_logs (appointment_id, log_message)
        VALUES (OLD.appointment_id, 'Completed appointment was deleted');
    END IF;
END //

DELIMITER ;
-- cau 6
CREATE VIEW FullRevenueReport AS
SELECT
    d.doctor_name,
    SUM(d.salary) AS total_doctor_revenue 
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_name;
-- cau 7
CALL GetDoctorDetails(1);  
-- cau 8
-- Delete a "Cancelled" appointment
DELETE FROM appointments WHERE appointment_id = 3;

-- Delete a "Completed" appointment
DELETE FROM appointments WHERE appointment_id = 2;
-- cau 9
SELECT * FROM FullRevenueReport;