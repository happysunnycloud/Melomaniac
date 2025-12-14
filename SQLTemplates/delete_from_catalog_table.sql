DELETE FROM 
	catalog
WHERE
	path = :path
	and
    file_name = :file_name;