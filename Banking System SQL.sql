CREATE DATABASE Banking_System;

USE Banking_System;

CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(100),
    location VARCHAR(100)
);

CREATE TABLE Accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    branch_id INT,
    account_type ENUM('Savings', 'Checking', 'Business'),
    balance DECIMAL(15,2) DEFAULT 0.00,
    opened_on DATE DEFAULT (CURRENT_DATE),
    status ENUM('Active', 'Closed') DEFAULT 'Active',
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES Branches(branch_id)
);

CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT,
    amount DECIMAL(10,2),
    transaction_type ENUM('Deposit', 'Withdrawal', 'Transfer'),
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    note TEXT,
    FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
);

CREATE TABLE Loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    loan_type ENUM('Home', 'Auto', 'Personal', 'Business'),
    amount DECIMAL(15,2),
    interest_rate DECIMAL(5,2),
    issued_date DATE,
    status ENUM('Approved', 'Pending', 'Rejected'),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE Employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    position VARCHAR(100),
    branch_id INT,
    email VARCHAR(100),
    phone VARCHAR(15),
    FOREIGN KEY (branch_id) REFERENCES Branches(branch_id)
);

CREATE TABLE Logins (
    login_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(100),
    last_login DATETIME,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

INSERT INTO Branches (branch_name, location) VALUES
('Main Branch', 'Hyderabad'),
('City Branch', 'Delhi'),
('West Side', 'Mumbai'),
('Tech Park', 'Bangalore');

INSERT INTO Customers (full_name, email, phone, address, date_of_birth) VALUES
('Alice Johnson', 'alice@example.com', '9876543210', '123 Street, Hyderabad', '1990-01-10'),
('Bob Smith', 'bob@example.com', '9876500000', '456 Avenue, Delhi', '1988-05-24'),
('Carol White', 'carol@example.com', '8765432109', '789 Boulevard, Mumbai', '1992-07-15'),
('David Green', 'david@example.com', '7654321098', '1011 Lane, Bangalore', '1985-09-30');

INSERT INTO Employees (name, position, branch_id, email, phone) VALUES
('Ravi Kumar', 'Manager', 1, 'ravi@bank.com', '9123456789'),
('Meena Iyer', 'Clerk', 2, 'meena@bank.com', '9234567890'),
('Rahul Das', 'Loan Officer', 3, 'rahul@bank.com', '9345678901');

INSERT INTO Accounts (customer_id, branch_id, account_type, balance) VALUES
(1, 1, 'Savings', 10000.00),
(2, 2, 'Checking', 15000.00),
(3, 3, 'Business', 25000.00),
(4, 4, 'Savings', 12000.00);

INSERT INTO Logins (customer_id, username, password) VALUES
(1, 'alicej', 'pass123'),
(2, 'bobsmith', 'bobpass'),
(3, 'carolw', 'carolpw'),
(4, 'davidg', 'davidpw');


INSERT INTO Transactions (account_id, amount, transaction_type, note) VALUES
(1, 2000, 'Deposit', 'Salary'),
(1, 500, 'Withdrawal', 'ATM withdrawal'),
(2, 3000, 'Deposit', 'Cheque'),
(2, 1000, 'Withdrawal', 'Online transfer'),
(3, 10000, 'Deposit', 'Business income'),
(3, 2000, 'Withdrawal', 'Vendor payment'),
(4, 1500, 'Deposit', 'Gift'),
(4, 300, 'Withdrawal', 'Recharge');

INSERT INTO Loans (customer_id, loan_type, amount, interest_rate, issued_date, status) VALUES
(1, 'Home', 5000000, 7.5, '2024-01-01', 'Approved'),
(2, 'Auto', 800000, 9.0, '2024-02-15', 'Pending'),
(3, 'Personal', 200000, 11.0, '2024-03-10', 'Rejected');
                                                                       
                                                                       -- Views
-- View customer account balances
CREATE VIEW CustomerBalances AS
SELECT c.full_name, a.account_id, a.account_type, a.balance
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id;

-- View loan summary
CREATE VIEW LoanSummary AS
SELECT l.loan_id, c.full_name, l.loan_type, l.amount, l.interest_rate, l.status
FROM Loans l
JOIN Customers c ON l.customer_id = c.customer_id;

-- Deposit Procedure                          --stored procedures
DELIMITER //
CREATE PROCEDURE DepositAmount(IN acc_id INT, IN amt DECIMAL(10,2))
BEGIN
    UPDATE Accounts SET balance = balance + amt WHERE account_id = acc_id;
    INSERT INTO Transactions(account_id, amount, transaction_type, note)
    VALUES (acc_id, amt, 'Deposit', 'Procedure deposit');
END;
//
DELIMITER ;

-- Withdraw Procedure
DELIMITER //
CREATE PROCEDURE WithdrawAmount(IN acc_id INT, IN amt DECIMAL(10,2))
BEGIN
    DECLARE current_balance DECIMAL(10,2);
    SELECT balance INTO current_balance FROM Accounts WHERE account_id = acc_id;

    IF current_balance >= amt THEN
        UPDATE Accounts SET balance = balance - amt WHERE account_id = acc_id;
        INSERT INTO Transactions(account_id, amount, transaction_type, note)
        VALUES (acc_id, amt, 'Withdrawal', 'Procedure withdrawal');
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;
END;
//
DELIMITER ;

-- Automatically close account if balance is 0          --Triggers
DELIMITER //
CREATE TRIGGER check_account_balance
AFTER UPDATE ON Accounts
FOR EACH ROW
BEGIN
    IF NEW.balance = 0 THEN
        UPDATE Accounts SET status = 'Closed' WHERE account_id = NEW.account_id;
    END IF;
END;
//
DELIMITER ;

-- Function to get total balance of customer                    --Functions
DELIMITER //
CREATE FUNCTION GetCustomerTotalBalance(cust_id INT) RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(15,2);
    SELECT SUM(balance) INTO total FROM Accounts WHERE customer_id = cust_id;
    RETURN IFNULL(total, 0);
END;
//
DELIMITER ;

-- Total balance per customer                          --CQ
SELECT c.full_name, GetCustomerTotalBalance(c.customer_id) AS total_balance
FROM Customers c;

-- Transaction history for a customer
SELECT t.transaction_id, t.transaction_type, t.amount, t.transaction_date
FROM Transactions t
JOIN Accounts a ON t.account_id = a.account_id
WHERE a.customer_id = 1;

-- Customers with loans above 1 lakh
SELECT c.full_name, l.amount
FROM Loans l
JOIN Customers c ON l.customer_id = c.customer_id
WHERE l.amount > 100000;

-- Loan count per status
SELECT status, COUNT(*) AS total_loans FROM Loans GROUP BY status;

