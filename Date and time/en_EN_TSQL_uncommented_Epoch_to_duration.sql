CREATE FUNCTION FN_EPOCH_TO_DURATION (@format CHAR(1), @inputSeconds INT) RETURNS VARCHAR(28) AS
BEGIN

	DECLARE @weeks VARCHAR(10)
	DECLARE @days VARCHAR(10)
	DECLARE @hms VARCHAR(8)
	DECLARE @formattedString VARCHAR(28)

	DECLARE @oneWeek INT = 604800
	DECLARE @oneDay INT = 86400

	SELECT @weeks = CASE
		WHEN @format = 'D' OR (@inputSeconds < @oneWeek) THEN NULL
	    WHEN (@inputSeconds >= @oneWeek * 2) THEN CAST((@inputSeconds / @oneWeek) AS VARCHAR(4)) + ' weeks'
		WHEN (@inputSeconds >= @oneWeek AND @inputSeconds < (@oneWeek * 2)) THEN '1 week'
		ELSE 'Error'
	END

	SELECT @days = CASE
		WHEN (@format = 'W') AND ((@inputSeconds < @oneDay) OR (@inputSeconds % (@oneWeek) < @oneDay) OR (@inputSeconds % (@oneWeek) = 0)) THEN NULL
		WHEN (@format = 'W') AND ((@inputSeconds >= @oneWeek) AND ((@inputSeconds - ((@inputSeconds / (@oneWeek)) * @oneWeek)) / @oneDay) != 1) THEN CAST((@inputSeconds - ((@inputSeconds / (@oneWeek)) * (@oneWeek))) / @oneDay AS VARCHAR(4)) + ' days'
	    WHEN (@format = 'W') AND (@inputSeconds >= @oneDay * 2 AND @inputSeconds < @oneWeek) THEN CAST(@inputSeconds / @oneDay AS VARCHAR(4)) + ' days'
	    WHEN (@format = 'W') AND ((@inputSeconds >= @oneDay AND @inputSeconds < @oneDay * 2) OR (((@inputSeconds - ((@inputSeconds / (@oneWeek)) * (@oneWeek))) / @oneDay) = 1)) THEN '1 day'
		WHEN (@format = 'D') AND (@inputSeconds >= @oneDay * 2) THEN CAST((@inputSeconds / @oneDay) AS VARCHAR(4)) + ' days'
		WHEN (@format = 'D') AND (@inputSeconds >= @oneDay) AND (@inputSeconds < @oneDay * 2) THEN '1 day'
		WHEN (@format = 'D') AND (@inputSeconds < @oneDay) THEN NULL
		ELSE 'Error'
	END

	SELECT @hms = CASE
		WHEN (@inputSeconds % @oneDay != 0) THEN CONVERT(VARCHAR(8), DATEADD(SECOND, @inputSeconds, 0), 108)
	    WHEN (@inputSeconds = @oneDay) OR (@inputSeconds % @oneDay = 0) THEN NULL
		ELSE 'Error'
	END

	SELECT @formattedString = CASE
		WHEN @weeks = 'Error' THEN 'Error 1: bad weeks calc.'
		WHEN @days = 'Error' THEN 'Error 2: bad days calc.'
		WHEN @hms = 'Error' THEN 'Error 3: bad HH:MM:SS calc.'
	    WHEN (@inputSeconds < 0) THEN 'Error 4: negative value'
	    WHEN (@inputSeconds = 0) THEN 'Nothing'
	    WHEN (@weeks IS NOT NULL AND @days IS NOT NULL AND @hms IS NOT NULL) THEN @weeks + ', ' + @days + ', ' + @hms
	    WHEN (@weeks IS NOT NULL AND @days IS NOT NULL AND @hms IS NULL) THEN @weeks + ', ' + @days
	    WHEN (@weeks IS NOT NULL AND @days IS NULL AND @hms IS NOT NULL) THEN @weeks + ', ' + @hms
	    WHEN (@weeks IS NOT NULL AND @days IS NULL AND @hms IS NULL) THEN @weeks
	    WHEN (@weeks IS NULL AND @days IS NOT NULL AND @hms IS NOT NULL) THEN @days + ', ' + @hms
	    WHEN (@weeks IS NULL AND @days IS NOT NULL AND @hms IS NULL) THEN @days
	    WHEN (@weeks IS NULL AND @days IS NULL AND @hms IS NOT NULL) THEN @hms
		ELSE 'Error 5: check function def.'
	END

	RETURN @formattedString
END