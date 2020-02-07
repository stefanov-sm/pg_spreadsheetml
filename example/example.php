<?php

// This CLI example runs against the popular DVD RENTAL sample database.
// It produces file 'delays.xml' in valid SpreadsheetML format. Open it with Excel.

define('XML_QUERY', 'SELECT xml_line from pg_spreadsheetml(?, ?) t(xml_line);');
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

// Obtain a PDO connection object in your preferred way
$conn = new PDO('pgsql:dbname=dvdrental;host=<host>;port=<port>;user=<user>;password=<password>');


// Allocate arguments
$arguments_object = (object)[];
$arguments_object -> Number_Of_Days = '7 days';
$arguments_object -> cost = 15.00;
$arguments_json = json_encode($arguments_object);

$rs = $conn -> prepare(XML_QUERY);
$rs -> execute([$report_query, $arguments_json]);
$xml_file = fopen('delays.xml', 'wb');
while (($xml_line = $rs -> fetchColumn()) !== FALSE)
{
  fputs($xml_file, $xml_line);
}
fclose($xml_file);
