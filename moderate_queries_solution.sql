-- Library Management System Project 2 - Part 1
-- Project Task CRUD | CTAS queries

USE library_project_p2;

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Project Task

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121';
SELECT * FROM issued_status;

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * 
FROM issued_status
WHERE issued_emp_id = 'E101';
SELECT * FROM issued_status;

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_emp_id, COUNT(*)
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;

SELECT * FROM issued_status;

-- CTAS (CREATE TABLE AS SELECT)
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_counts
AS
SELECT
	b.isbn,
    b.book_title,
    COUNT(ist.issued_id) AS no_issued
FROM books b
JOIN issued_status ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1, 2;

SELECT * FROM book_counts;

-- Task 7. Retrieve All Books in a Specific Category:
SELECT * FROM books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category:

SELECT
	b.category,
    SUM(b.rental_price) AS total_price,
    COUNT(*)
FROM books b
JOIN issued_status ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1
ORDER BY 2 DESC;

-- Task 9: List Members Who Registered in the Last 180 Days:
SELECT * 
FROM members
WHERE reg_date >= curdate() - INTERVAL 365 DAY;

-- Task 10: List Employees with Their Branch Manager's Name and their branch details:
SELECT 
	e1.*,
    b.manager_id,
	e2.emp_name AS manager
FROM employees e1
JOIN branch b
ON b.branch_id = e1.branch_id
JOIN employees e2
ON b.manager_id = e2.emp_id;

-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE books_high_rental_price
AS 
SELECT * FROM books
WHERE rental_price > 7;

SELECT * FROM books_high_rental_price;

-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT 
	DISTINCT ist.issued_book_name 
FROM issued_status ist
LEFT JOIN return_status rst
	ON ist.issued_id = rst.issued_id
WHERE return_id IS NULL;

