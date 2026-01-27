SELECT 
	path,
	file_name,
	title,
	artist,
	album,
	year,
	CAST(duration AS TEXT) AS duration
FROM catalog c
JOIN (
    SELECT file_size, md5, sha256
    FROM catalog
    GROUP BY file_size, md5, sha256
    HAVING COUNT(*) > 1
) dup
ON c.file_size = dup.file_size
   AND c.md5 = dup.md5
   AND c.sha256 = dup.sha256
WHERE
	path = :path   
ORDER BY c.file_size, c.md5, c.sha256;
 