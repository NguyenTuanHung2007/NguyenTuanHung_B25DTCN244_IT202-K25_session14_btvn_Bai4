DROP PROCEDURE IF EXISTS SafeHospitalPayment;

DELIMITER //
CREATE PROCEDURE SafeHospitalPayment(
    IN p_patient_id INT, 
    IN p_amount DECIMAL(18,2), 
    OUT p_status_message VARCHAR(255)
)
BEGIN
    DECLARE v_current_balance DECIMAL(18,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_message = 'Lỗi hệ thống: Giao dịch đã được hoàn nguyên an toàn.';
    END;
    IF p_amount <= 0 THEN
        SET p_status_message = 'Lỗi: Số tiền thanh toán phải lớn hơn 0.';
    ELSE
        SELECT balance INTO v_current_balance FROM Wallets 
        WHERE patient_id = p_patient_id;

        IF v_current_balance IS NULL THEN
            SET p_status_message = 'Lỗi: Không tìm thấy thông tin ví của bệnh nhân.';
        ELSEIF v_current_balance < p_amount THEN
            SET p_status_message = 'Lỗi: Số dư ví không đủ để thanh toán.';
        ELSE
            START TRANSACTION;
            UPDATE Wallets 
            SET balance = balance - p_amount 
            WHERE patient_id = p_patient_id;

            UPDATE Patient_Invoices 
            SET total_due = total_due - p_amount 
            WHERE patient_id = p_patient_id;

            COMMIT;
            SET p_status_message = 'Thanh toán thành công.';
        END IF;
    END IF;
END
// DELIMITER ;