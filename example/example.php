<?php

// This CLI example is run against the popular DVDRENTAL sample database.
// It produces file 'delays.xml' in valid SpreadsheetML format. Open it with Excel.

define('ML_QUERY', 'SELECT xml_line from pg_spreadsheetml(?, ?) t(xml_line);');
$report_query = <<<SQL
SELECT r.rental_date, r.return_date, c.first_name, c.last_name, c.email, f.title, f.replacement_cost 
  FROM rental r
   INNER JOIN customer c ON r.customer_id = c.customer_id 
   INNER JOIN inventory i ON r.inventory_id = i.inventory_id
   INNER JOIN film f ON i.film_id = f.film_id
  WHERE r.return_date - r.rental_date > '__NUMBER_OF_DAYS__'::interval
  AND f.replacement_cost > __COST__
  ORDER by r.return_date - r.rental_date DESC;
SQL;

$conn = new PDO('pgsql:dbname=playground;host=172.30.0.10;port=5432;user=phpUser;password=Baba123Meca');

// Obtain a PDO connection object in your preferred way
// $conn = new PDO('pgsql:dbname=dvdrental;host=<host>;port=<port>;user=<user>;password=<password>');

$arguments = [];
$arguments['Number_Of_Days'] = '7 days';
$arguments['cost'] = 15.00;

$rs = $conn -> prepare(ML_QUERY);
$rs -> execute([$report_query, json_encode((object)$arguments)]);
$xml_file = fopen('delays.xml', 'wb');
while (($xml_line = $rs -> fetchColumn()) !== FALSE)
{
	fputs($xml_file, $xml_line);
};
fclose($xml_file);