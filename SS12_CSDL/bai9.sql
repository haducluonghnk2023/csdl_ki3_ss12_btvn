CREATE DATABASE ss10_9;
USE ss10_9;
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE
);
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    salary DECIMAL(10, 2) NOT NULL
);
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_datetime DATETIME NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled') NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    medicine_name VARCHAR(100) NOT NULL,
    dosage VARCHAR(150) NOT NULL,	
    duration VARCHAR(50) NOT NULL,
    notes VARCHAR(255),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);
CREATE TABLE patient_error_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_name VARCHAR(100),
    phone_number VARCHAR(15),
    error_message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- cau 3
DELIMITER //

CREATE TRIGGER before_patient_insert
BEFORE INSERT ON patients
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM patients
        WHERE patient_name = NEW.patient_name AND dob = NEW.dob
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient already exists';
        INSERT INTO patient_error_log (patient_name, phone_number, error_message)
        VALUES (NEW.patient_name, NEW.phone, 'Patient already exists');
    END IF;
END //
DELIMITER ;
-- cau 4
-- Valid patient
INSERT INTO patients (patient_name, dob, gender, phone) VALUES ('John Doe', '1990-01-01', 'Male', '1234567890');

-- cau 5
DELIMITER //

CREATE TRIGGER CheckPhoneNumberFormat
BEFORE INSERT ON patients
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.phone) != 10 OR NEW.phone NOT REGEXP '^[0-9]+$' THEN
        -- Prevent insertion
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid phone number format!';

        -- Log the error
        INSERT INTO patient_error_log (patient_name, phone_number, error_message)
        VALUES (NEW.patient_name, NEW.phone, 'Invalid phone number format!');
    END IF;
END //

DELIMITER ;
-- cau 6
INSERT INTO patients (patient_name, dob, gender, phone) VALUES
('Alice Smith', '1985-06-15', 'Female', '1234567895'),
('Bob Johnson', '1990-02-25', 'Male', '2345678901'),
('Carol Williams', '1975-03-10', 'Female', '3456789012'),
('Dave Brown', '1992-09-05', 'Male', '4567890abc'), 
('Eve Davis', '1980-12-30', 'Female', '56789xyz'),  
('Eve', '1980-12-13', 'Female', '56789');       
-- cau 7
SELECT * FROM patient_error_log;
-- cau 8
DELIMITER //

CREATE PROCEDURE UpdateAppointmentStatus (
    IN appointment_id_param INT,
    IN status_param VARCHAR(50)
)
BEGIN
    UPDATE appointments
    SET status = status_param
    WHERE appointment_id = appointment_id_param;
END //

DELIMITER ;
-- cau 9
DELIMITER //

CREATE TRIGGER UpdateStatusAfterPrescriptionInsert
AFTER INSERT ON prescriptions
FOR EACH ROW
BEGIN
    CALL UpdateAppointmentStatus(NEW.appointment_id, 'Completed');
END //

DELIMITER ;
-- cau 10
-- Insert doctors
INSERT INTO doctors (doctor_name, specialization, phone, salary)
VALUES ('Dr. John Smith', 'Cardiology', '1234567890', 5000.00);
INSERT INTO doctors (doctor_name, specialization, phone, salary)
VALUES ('Dr. Alice Brown', 'Neurology', '0987654321', 6000.00);

-- Insert appointments
INSERT INTO appointments (patient_id, doctor_id, appointment_datetime, status)
VALUES (1, 1, '2025-02-15 09:00:00', 'Scheduled');
INSERT INTO appointments (patient_id, doctor_id, appointment_datetime, status)
VALUES (2, 2, '2025-02-16 10:00:00', 'Scheduled');
INSERT INTO appointments (patient_id, doctor_id, appointment_datetime, status)
VALUES (3, 1, '2025-02-17 14:00:00', 'Scheduled');

-- ALTER TABLE appointments DROP FOREIGN KEY appointments_ibfk_1;
-- cau 11
-- Before inserting prescription
SELECT * FROM appointments WHERE appointment_id = 1;

-- Insert prescription (this will trigger the update)
INSERT INTO prescriptions (appointment_id, medicine_name, dosage, duration, notes)
VALUES (1, 'Paracetamol', '500mg', '5 days', 'Take one tablet every 6 hours');

-- After inserting prescription
SELECT * FROM appointments WHERE appointment_id = 1;