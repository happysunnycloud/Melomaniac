SELECT 
		path,
		file_name,
		title,
		artist,
		album,
		year,
		duration
FROM 
		catalog
WHERE
		path = :path
 