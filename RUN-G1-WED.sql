--Neha Ramachandar
--Mallika Goyal
--Rishabh Rao
--Bharath Reddy Chada
--Prakash Reddy Padamati
--Abhilash Tipirneni
--Omer Mohammed

---------------------------------------------------------------------------------------------------

--TABLE 1 : Studio wise Investment Analysis
--Showcasing top studios which own the highest rated and most popular animes

SELECT
    P.Studios,
    AVG(R.Score) AS AvgRating,
	AVG(A.Popularity) AS AvgPopularity
FROM
    Rating R
JOIN
    ProductionTeam P 
		ON R.Producers_ID = P.Producers_ID
JOIN 
    Telecast T 
		ON P.Broadcast_ID=T.Broadcast_ID
JOIN
    Anime A 
		ON T.Telecast_Id=A.Telecast_Id
GROUP BY
    P.Studios
ORDER BY AVG(R.Score) DESC;

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

--TABLE 2: Binge Watch
--Showcasing popular animes which have finished airing.(Binge watch worthy!!)

SELECT
    A.Title,
    P.Genres,
	A.Status,
    AVG(R.Popularity) AS AveragePopularity
FROM
    Rating R
JOIN
    ProductionTeam P 
		ON R.Producers_ID = P.Producers_ID
JOIN 
    Telecast T 
		ON P.Broadcast_ID = T.Broadcast_ID
JOIN
    Anime A		
		ON T.Telecast_Id = A.Telecast_Id
WHERE
    A.Status = 'Finished Airing'
	AND  R.Score IS NOT NULL
	AND P.Genres != 'Unknown'
GROUP BY
    A.Title, P.Genres, A.Status
HAVING
    AVG(R.Popularity) >= (SELECT AVG(Popularity) FROM Rating) + 500
ORDER BY
    AVG(R.Popularity) DESC;

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

--TABLE 3: Genre Wise Engagement
--Showcasing the popularity for each genre with total number of animes.

USE [PROJECT G1];
IF OBJECT_ID('dbo.GenreEngagement') IS NOT NULL 
DROP VIEW dbo.GenreEngagement
GO
CREATE VIEW GenreEngagement AS
SELECT
    P.Genres,
    AVG(R.Popularity) AS AvgPopularity,
    COUNT(A.Telecast_ID) AS TotalAnime
FROM
    Rating R
JOIN
    ProductionTeam P 
		ON R.Producers_ID = P.Producers_ID
JOIN 
    Telecast T 
		ON P.Broadcast_ID = T.Broadcast_ID
JOIN
    Anime A 
		ON T.Telecast_ID = A.Telecast_ID
GROUP BY
    P.Genres
GO

-- Execute statement--

SELECT *
FROM 
	GenreEngagement
ORDER BY 
	AvgPopularity DESC;
GO

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

--TABLE 4: Anime Plot
--Showcasing the animes plot with their English alias along with scores given by the viewers.

USE [PROJECT G1];
IF OBJECT_ID('AnimeInfoWithSynopsis') IS NOT NULL 
DROP VIEW dbo.AnimeInfoWithSynopsis
GO
CREATE VIEW AnimeInfoWithSynopsis AS
SELECT
    A.Title,
    A.Synopsis,
    A.English,
	R.Score,
    R.Scored_Users   
FROM
    Rating R
JOIN
    ProductionTeam P 
		ON R.Producers_ID = P.Producers_ID
JOIN 
    Telecast T 
		ON P.Broadcast_ID = T.Broadcast_ID
JOIN
    Anime A 
		ON T.Telecast_ID = A.Telecast_ID
WHERE Synopsis IS NOT NULL;
GO

--Execute Statement--

SELECT *
FROM AnimeInfoWithSynopsis;
GO

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

--TABLE 5: Anime Based Upon Source
--Showcasing the information on animes based on their derived source.(For eg, Manga, Light Novel)

USE [PROJECT G1];
IF OBJECT_ID('dbo.GetAnimeTitlesBySource') IS NOT NULL 
DROP PROCEDURE dbo.GetAnimeTitlesBySource
GO
CREATE PROCEDURE GetAnimeTitlesBySource @sourceName VARCHAR(255)
AS
BEGIN
    SELECT
        A.Title,
        P.Genres,
        P.Studios,
        R.Score AS AverageRating,
        P.Producers AS ProductionTeam
FROM
    Rating R
JOIN
    ProductionTeam P 
		ON R.Producers_ID = P.Producers_ID
JOIN 
    Telecast T 
		ON P.Broadcast_ID = T.Broadcast_ID
JOIN
    Anime A 
		ON T.Telecast_ID = A.Telecast_ID
    
WHERE
    P.Source =@sourceName;
END;
GO

-- Execute statement--

EXEC dbo.GetAnimeTitlesBySource @sourceName = 'Manga';

------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------

--TABLE 6: Impact Of CensorBoard
--Presenting the ratings and scores assigned by a specific censor board for the anime production.

USE [PROJECT G1];
IF OBJECT_ID('dbo.AnalyzeCensorBoardImpact') IS NOT NULL 
DROP PROCEDURE dbo.AnalyzeCensorBoardImpact
GO

CREATE PROCEDURE AnalyzeCensorBoardImpact 
AS
BEGIN
    DECLARE @Licensor VARCHAR(255) = 'Funimation';

    SELECT
        Licensors AS Censor_Board,
		Rating,
        AVG(Score) AvgScore
    FROM
    Rating R

JOIN
    ProductionTeam P 
		ON R.Producers_ID = P.Producers_ID
JOIN 
    Telecast T 
		ON P.Broadcast_ID = T.Broadcast_ID
JOIN
    Anime A 
		ON T.Telecast_ID = A.Telecast_ID

    WHERE Licensors LIKE '%' + @Licensor + '%'
    GROUP BY
		Licensors, Rating;
END;
GO

--Execute statement--

EXEC AnalyzeCensorBoardImpact;

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--TABLE 7: Anime Duration
--Determining the number of episodes for a specific anime.

USE [PROJECT G1];
IF OBJECT_ID('dbo.fnGetEpisodeCountForAnime') IS NOT NULL 
    DROP FUNCTION dbo.fnGetEpisodeCountForAnime;
GO

CREATE FUNCTION dbo.fnGetEpisodeCountForAnime(@animeTitle VARCHAR(255))
RETURNS INT
AS
BEGIN
    DECLARE @episodeCount INT;
    SELECT @episodeCount = Episodes
    FROM Rating R

         JOIN ProductionTeam P ON R.Producers_ID = P.Producers_ID

         JOIN Telecast T ON P.Broadcast_ID = T.Broadcast_ID

         JOIN Anime A ON T.Telecast_ID = A.Telecast_ID

    WHERE A.Title = @animeTitle;
    RETURN @episodeCount;
END;
GO

--Execute statement--

DECLARE @AnimeTitle nvarchar(50);
SET @AnimeTitle = 'Death Note';
PRINT 'The count of the episodes for Anime '+ @AnimeTitle +' '+ CONVERT(nvarchar(20) , dbo.fnGetEpisodeCountForAnime(@AnimeTitle));

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

--TABLE 8: Anime Fusion Score
--Determining a fusion score by considering Rating and by giving more weight to popularity for each anime.

USE [PROJECT G1];
IF OBJECT_ID('dbo.fnCalculateWeightedScore') IS NOT NULL 
DROP FUNCTION dbo.fnCalculateWeightedScore;
GO
CREATE FUNCTION dbo.fnCalculateWeightedScore(@Score FLOAT, @Popularity INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @WeightedScore FLOAT;
    
    SET @WeightedScore = (0.7*@Score) + (0.3*@Popularity);

    RETURN ROUND(@WeightedScore,2);
END;
GO

--Execute Statement--

SELECT Title, ROUND(Score,2) AS Score, Anime.Popularity, 
	dbo.fnCalculateWeightedScore(Score, Anime.Popularity) AS Unified_Score
FROM 
	Anime
JOIN 
	Rating
ON 
	Anime.Popularity= Rating.Popularity;

----------------------------------------------------------------------------------------------------------------

