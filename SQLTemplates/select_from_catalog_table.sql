SELECT 
		path,
		file_name,
		title,
		artist,
		album,
		year,
		CAST(duration AS TEXT) AS duration
FROM 
		catalog
WHERE
		path = :path
 