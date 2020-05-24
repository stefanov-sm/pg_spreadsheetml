COPY
(
 SELECT xml_line FROM pg_spreadsheetml
 (
  $$
  SELECT r.rental_date, r.return_date, c.first_name, c.last_name, c.email, f.title, f.replacement_cost 
    FROM rental r
     INNER JOIN customer c ON r.customer_id = c.customer_id 
     INNER JOIN inventory i ON r.inventory_id = i.inventory_id
     INNER JOIN film f ON i.film_id = f.film_id
    WHERE r.return_date - r.rental_date > '__NUMBER_OF_DAYS__'::interval
    AND f.replacement_cost > __COST__
    ORDER by r.return_date - r.rental_date DESC;
  $$,
  '{"Number_Of_Days": "7 days", "cost": 15.00}'::json
 ) t(xml_line)
)
TO '-- path-to --/delme.xml';