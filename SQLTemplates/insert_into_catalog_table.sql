INSERT INTO catalog (
                        path,
                        file_name,
                        title,
                        artist,
                        album,
                        year,
                        duration,
                        md5,
                        sha256,
                        file_size
                    )
                    VALUES (
                        :path,
                        :file_name,
                        :title,
                        :artist,
                        :album,
                        :year,
                        :duration,
                        :md5,
                        :sha256,
                        :file_size
                    );
