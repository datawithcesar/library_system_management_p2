-- SQL Project - Library Management System Part2
-- 

USE library_project_p2;

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;
SELECT * FROM book_counts;
SELECT * FROM books_high_rental_price;

/*Task 13: 
Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
*/

-- At first, need to JOIN (issued_status == members == books == return_status)
-- Filter books which is return 
-- Overdue > 365 days

SELECT CURDATE();

SELECT
	ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    rst.return_date,
    DATEDIFF(CURDATE(), ist.issued_date) AS over_dues_days
FROM issued_status ist
JOIN members m
	ON m.member_id = ist.issued_member_id
JOIN books bk
	ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rst
	ON rst.issued_id = ist.issued_id
WHERE rst.return_date IS NULL
	AND DATEDIFF(CURDATE(), ist.issued_date) > 365
ORDER BY 1;

/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/


INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
VALUES
('RS125', 'IS130', CURDATE(), 'Good');

SELECT *
FROM return_status;

-- Store Procedures

DROP PROCEDURE IF EXISTS add_return_records;

DELIMITER $$

CREATE PROCEDURE add_return_records(
	IN p_return_id VARCHAR(10), 
    IN p_issued_id VARCHAR(10), 
    IN p_book_quality VARCHAR(15)
)

BEGIN			-- all your logic and code inside begin and end
DECLARE v_isbn VARCHAR(25);
DECLARE v_book_name VARCHAR(70);
    
	-- inserting into returns based on users input
	INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
	VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);
    
    -- Get ISBN and book title
    SELECT 
		issued_book_isbn,
		issued_book_name
	INTO 
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;
    
    -- Update book status
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;
    
    -- Simulate Raise Notice like PostgreSQL
    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;
    
END$$

DELIMITER ;

CALL add_return_records();

-- Testing FUNCTION add_return_records | Parameters (p_return_id, p_issued_id, p_book_quality)

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- Calling Function Testing
CALL add_return_records('RS138', 'IS135', 'Good'); 

-- Second entry testing
SELECT * FROM books
WHERE isbn = '978-0-330-25864-8';

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-330-25864-8';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-330-25864-8';
-- IS140

CALL add_return_records('RS148', 'IS140', 'Good'); 

/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/

-- I need the following JOINS
SELECT * FROM branch;
SELECT * FROM issued_status;
SELECT * FROM employees;
SELECT * FROM books;
SELECT * FROM return_status;

CREATE TABLE branch_reports
AS
SELECT
	b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS number_book_issued,
    COUNT(rs.return_id) AS number_book_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees AS e
ON e.emp_id = ist.issued_emp_id
JOIN branch AS b
ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs
ON rs.issued_id = ist.issued_id
JOIN books AS bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;

/*Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 12 months.
*/

CREATE TABLE active_members
AS 
SELECT * 
FROM members
WHERE member_id IN (
					SELECT 
						issued_member_id
					FROM issued_status
					WHERE issued_date >= CURDATE() - INTERVAL 12 MONTH
					)
;

/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
*/

SELECT
	e.emp_name,
    b.*,
    COUNT(ist.issued_id) AS number_book_issued
FROM issued_status ist
JOIN employees e
ON e.emp_id = ist.issued_emp_id
JOIN branch b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;

/*
Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books.
*/

/*Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

SELECT * FROM branch;
SELECT * FROM issued_status;
SELECT * FROM employees;
SELECT * FROM books;
SELECT * FROM return_status;

DROP PROCEDURE IF EXISTS issue_book;

DELIMITER $$

CREATE PROCEDURE issue_book(
	IN p_issued_id VARCHAR(10), 
    IN p_issued_member_id VARCHAR(10), 
    IN p_issued_book_isbn VARCHAR(25), 
    IN p_issued_emp_id VARCHAR(10)
)
    
BEGIN -- all your code checking if book is available
DECLARE -- all the variable
	v_status VARCHAR(15);

SELECT 
	status
    INTO v_status
FROM books
WHERE isbn = p_issued_book_isbn;

IF v_status = 'yes' THEN  
	INSERT INTO issued_status(issued_id, issued_member_id, issued_book_isbn, issued_date, issued_emp_id)
		VALUES (p_issued_id, p_issued_member_id, p_issued_book_isbn, CURDATE(), p_issued_emp_id);

    UPDATE books
    SET status = 'no'
    WHERE isbn = p_issued_book_isbn;        

	SELECT CONCAT('Book records added successfully for book isbn : ', p_issued_book_isbn) AS message;
ELSE
	SELECT CONCAT('Sorry to inform you, the book you have requested is unavailable book_isbn: ', p_issued_book_isbn) AS message;

END IF;

END$$
DELIMITER ;

SELECT * FROM books;
-- '978-0-553-29698-2' --yes--
-- '978-0-375-41398-8' --no--
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');

CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

--     -- Simulate Raise Notice like PostgreSQL
--     SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;

/*Task 20: Create Table As Select (CTAS) 
Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. 
The resulting table should show: Member ID Number of overdue books Total fines
*/

