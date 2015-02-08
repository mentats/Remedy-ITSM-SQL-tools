CREATE FUNCTION FN_EPOCH_A_DURACION (@formato CHAR(1), @inputSegundos INT) RETURNS VARCHAR(28) AS
BEGIN

	DECLARE @semanas VARCHAR(10)
	DECLARE @dias VARCHAR(10)
	DECLARE @hms VARCHAR(8)
	DECLARE @cadenaFormateada VARCHAR(35)

	DECLARE @unaSemana INT = 604800
	DECLARE @unDia INT = 86400

	SELECT @semanas = CASE
		WHEN @formato = 'D' OR (@inputSegundos < @unaSemana) THEN NULL
	    WHEN (@inputSegundos >= @unaSemana * 2) THEN CAST((@inputSegundos / @unaSemana) AS VARCHAR(4)) + ' semanas'
		WHEN (@inputSegundos >= @unaSemana AND @inputSegundos < (@unaSemana * 2)) THEN '1 semana'
		ELSE 'Error'
	END
	
	SELECT @dias = CASE
		WHEN (@formato = 'W') AND ((@inputSegundos < @unDia) OR (@inputSegundos % (@unaSemana) < @unDia) OR (@inputSegundos % (@unaSemana) = 0)) THEN NULL
		WHEN (@formato = 'W') AND ((@inputSegundos >= @unaSemana) AND ((@inputSegundos - ((@inputSegundos / (@unaSemana)) * @unaSemana)) / @unDia) != 1) THEN CAST((@inputSegundos - ((@inputSegundos / (@unaSemana)) * (@unaSemana))) / @unDia AS VARCHAR(4)) + ' días'
	    WHEN (@formato = 'W') AND (@inputSegundos >= @unDia * 2 AND @inputSegundos < @unaSemana) THEN CAST(@inputSegundos / @unDia AS VARCHAR(4)) + ' días'
	    WHEN (@formato = 'W') AND ((@inputSegundos >= @unDia AND @inputSegundos < @unDia * 2) OR (((@inputSegundos - ((@inputSegundos / (@unaSemana)) * (@unaSemana))) / @unDia) = 1)) THEN '1 día'
		WHEN (@formato = 'D') AND (@inputSegundos >= @unDia * 2) THEN CAST((@inputSegundos / @unDia) AS VARCHAR(4)) + ' días'
		WHEN (@formato = 'D') AND (@inputSegundos >= @unDia) AND (@inputSegundos < @unDia * 2) THEN '1 día'
		WHEN (@formato = 'D') AND (@inputSegundos < @unDia) THEN NULL
		ELSE 'Error'
	END
	
	SELECT @hms = CASE
		WHEN (@inputSegundos % @unDia != 0) THEN CONVERT(VARCHAR(8), DATEADD(SECOND, @inputSegundos, 0), 108)
	    WHEN (@inputSegundos = @unDia) OR (@inputSegundos % @unDia = 0) THEN NULL
		ELSE 'Error'
	END

	SELECT @cadenaFormateada = CASE
		WHEN @semanas = 'Error' THEN 'Error 1: fallo cálculo de semanas'
		WHEN @dias = 'Error' THEN 'Error 2: fallo cálculo de días'
		WHEN @hms = 'Error' THEN 'Error 3: fallo cálculo de HH:MM:SS'
	    WHEN (@inputSegundos < 0) THEN 'Error 4: valor negativo'
	    WHEN (@inputSegundos = 0) THEN 'Nada'
	    WHEN (@semanas IS NOT NULL AND @dias IS NOT NULL AND @hms IS NOT NULL) THEN @semanas + ', ' + @dias + ', ' + @hms
	    WHEN (@semanas IS NOT NULL AND @dias IS NOT NULL AND @hms IS NULL) THEN @semanas + ', ' + @dias
	    WHEN (@semanas IS NOT NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @semanas + ', ' + @hms
	    WHEN (@semanas IS NOT NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @semanas
	    WHEN (@semanas IS NULL AND @dias IS NOT NULL AND @hms IS NOT NULL) THEN @dias + ', ' + @hms
	    WHEN (@semanas IS NULL AND @dias IS NOT NULL AND @hms IS NULL) THEN @dias
	    WHEN (@semanas IS NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @hms
		ELSE 'Error 5: revisar función'
	END

	RETURN @cadenaFormateada
END