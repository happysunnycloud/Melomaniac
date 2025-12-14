INSERT INTO catalog (
                        path,
                        file_name,
                        title,
                        artist,
                        album,
                        year,
                        duration
                    )
                    VALUES (
                        :path,
                        :file_name,
                        :title,
                        :artist,
                        :album,
                        :year,
                        :duration
                    );