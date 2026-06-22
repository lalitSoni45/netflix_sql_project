-- netflix Project

-- 1. Count the number of Movies vs TV Shows
    SELECT type,
	       COUNT(*) AS total 
	FROM netflix 
	GROUP BY type;

-- 2. Find the most common rating for movies and TV shows
     SELECT type,rating,rating_count
     FROM (SELECT type,
	              rating,
				  COUNT(*) AS rating_count , 
				  RANK() OVER( PARTITION BY type
				               ORDER BY COUNT(*) DESC) AS rn 
           FROM netflix 
     	   GROUP BY type,rating 
     	  )
     WHERE rn=1;
                          -- OR --

	  SELECT type, 
	         rating,
			 COUNT(*) AS total
      FROM netflix
      GROUP BY type, rating
      ORDER BY  COUNT(*) DESC;

-- 3. List all movies released in a specific year (e.g., 2020)
      SELECT * 
	  FROM netflix 
	  WHERE type='Movie' AND release_year=2020;

-- 4. Find the top 5 countries with the most content on Netflix
      SELECT country_name,content_count
      FROM(
            SELECT 
                TRIM( UNNEST(STRING_TO_ARRAY(country,','))) AS country_name,
				COUNT(*) AS content_count
            FROM netflix 
      	    GROUP BY country_name
      	    ORDER BY content_count DESC
          ) as t LIMIT 5;

                    -- OR --
					
	  SELECT TRIM(country_name) AS country_name ,
	         COUNT(*)
      FROM netflix,
      UNNEST(STRING_TO_ARRAY(country,',')) country_name
      GROUP BY 1
      ORDER BY 2 DESC
      LIMIT 5;	  
		  
-- 5. Identify the longest movie or TV show duration

    SELECT 
           MAX(
		     CASE 
		       WHEN type='Movie'
               THEN CAST(SPLIT_PART(duration,' ',1) AS INT)
			 END
		   ) AS longest_movie_duration
		   ,
		    MAX(
		     CASE 
		       WHEN type='TV Show'
               THEN CAST(SPLIT_PART(duration,' ',1) AS INT)
			 END
		   )AS longest_tvshow_duration
	FROM netflix; 

	                -- OR --

     SELECT 
	     title,
		 type,
		 duration 
	 FROM
	     ( WITH cte AS
	     (
            SELECT *,
	               CAST(SPLIT_PART(duration,' ',1) AS INT) AS dur
	        FROM netflix
	     )
	     SELECT *
	     FROM cte 
	     WHERE (type='Movie' AND dur=(SELECT MAX(dur) FROM cte WHERE type='Movie'))
	           or (type='TV Show' AND dur=( SELECT MAX(dur) FROM cte WHERE type='TV Show'))
		 ) AS T;
		 


-- 6. Find content added in the last 5 years

        SELECT * 
		FROM netflix
		WHERE 
		    to_date(date_added,'month dd,year')>=CURRENT_DATE-INTERVAL '5 years';


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'

       SELECT  title,director
	   FROM netflix
	   WHERE director 
	   ILIKE '%Rajiv Chilaka%';

 
-- 8. List all TV shows with more than 5 seasons
   
   SELECT * 
   FROM netflix 
   WHERE 
      type='TV Show' AND SPLIT_PART(duration,' ',1)::NUMERIC>5;
   
-- 9. Count the number of content items in each genre

   SELECT 
      TRIM(UNNEST(STRING_TO_ARRAY(listed_in,','))) AS genre,
	  COUNT(*) AS total
   FROM netflix 
   GROUP BY 1
   ORDER BY 2 DESC;

   
-- 10. Find each year and the average numbers of content release in India on netflix.
-- return top 5 year with highest avg content release !

   SELECT 
     EXTRACT ( YEAR FROM TO_DATE(date_added,'month dd, yyyy')) AS year ,
     COUNT(*) AS total_content,
     ROUND(
	       COUNT(*)::numeric/
		   (SELECT COUNT(*) FROM netflix WHERE country ILIKE '%India%'):: numeric
		   * 100,
		   2
		   ) AS content_percentage
   FROM netflix
   WHERE country ILIKE '%India%'
   GROUP BY 1
   ORDER BY content_percentage DESC
   LIMIT 5;


-- 11. List all movies that are documentaries

    SELECT
       title,
	   type,
	   listed_in 
    FROM netflix
    WHERE type='Movie' AND listed_in 
	ILIKE '%Documentaries%';


-- 12. Find all content without a director

      SELECT *
	  FROM netflix 
	  WHERE director is NULL;


-- 13. Find how many movies actor 'Salman Khan' appeared in during the last 10 years

      SELECT * 
      FROM netflix
      WHERE casts
      ILIKE '%Salman Khan%' AND release_year>EXTRACT(YEAR FROM CURRENT_DATE)-10 ;


-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India
india me bani he  sabse jada movies me dikhai diya ho

      SELECT  
	      TRIM(actor) AS actor,
		  count(*) AS movis_count
      FROM netflix ,UNNEST(STRING_TO_ARRAY(casts,',')) AS actor
      WHERE country ILIKE '%india%' AND type='Movie' 
      GROUP BY TRIM(actor)
      ORDER BY COUNT(*)DESC 
      LIMIT 10;


-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field.
--     Label content containing these keywords as 'Bad' and all other content as 'Good'.
--     Count how many items fall into each category.

        SELECT  category,COUNT(*)
        FROM    
        (
        	  SELECT 
        	  description,
              CASE WHEN description  ~*'\mKill' OR description  ~*'\mviolence'
              THEN 'BAD'
              ELSE 'GOOD'
              END AS category
              FROM netflix 
        	  )  AS t
        GROUP BY category;
		
                       -- OR--
        
		WITH cte as
        (
            SELECT description,
        	CASE WHEN description ~* '\m(kill|violence)' 
        	     THEN 'BAD'
        	     ELSE 'GOOD'
        	END AS category 
        	FROM netflix
        )
        
      SELECT description ,category,count(*) OVER(PARTITION BY category ) FROM cte;


