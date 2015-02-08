-- Crear función FN_EPOCH_A_DURACION (@entradas y TIPOS) DEVUELVE salida(LONGITUD)
CREATE FUNCTION FN_EPOCH_A_DURACION (@formato CHAR(1), @inputSegundos INT) RETURNS VARCHAR(28) AS
BEGIN
	-- Las variables son de longitud variable (VARCHAR en lugar de CHAR) de manera que la salida
	-- no esté llena de espacios vacíos y la cadena tenga un formato correcto.
	DECLARE @semanas VARCHAR(10)
	DECLARE @dias VARCHAR(10)
	DECLARE @hms VARCHAR(8)
	DECLARE @cadenaFormateada VARCHAR(35)

	-- Para facilitar la lectura, se declaran variables que contienen el número de segundos
	-- en una semana y en un día, se usarán para los cálculos siempre que sea posible.
	DECLARE @unaSemana INT = 604800
	DECLARE @unDia INT = 86400

	/* Cada una de las siguientes tres sentencias SELECT contiene una expresión CASE que establece
	un valor en cada una de las tres primeras variables que se definen en esta función. El formato
	varía en función del parámetro de entrada @formato que se reciba, de la siguiente manera:
	- "W" (de Weeks) devolverá el resultado en formato: "SS Semanas, DD días, HH:MM:SS"
	- "D" (de Días) lo devolverá así: "DD días, HH:MM:SS" 

	Las expresiones CASE causan break tras leer una condición true, de modo que el orden de las lineas 
	es importante en algunos casos. Por ejemplo, la primera SELECT tiene un CASE con tres posibles 
	opciones. Si movemos la primera de ellas abajo del todo, una de las otras se cumplirá primero y 
	llamar a esta función con la opción "D" en el primer parámetro no funcionará correctamente */

	-- Calcular semanas
	SELECT @semanas = CASE
		-- Si @formato es D o la entrada es menos de una semana, devuelve null.
		WHEN @formato = 'D' OR (@inputSegundos < @unaSemana) THEN NULL
		-- Si la entrada es dos o más semanas, devuelve el número de semanas + cadena en plural
	    WHEN (@inputSegundos >= @unaSemana * 2) THEN CAST((@inputSegundos / @unaSemana) AS VARCHAR(4)) + ' semanas'
		-- Si la entrada es una semana o más pero menos de dos semanas, devuelve una cadena en singular:
		WHEN (@inputSegundos >= @unaSemana AND @inputSegundos < (@unaSemana * 2)) THEN '1 semana'
		-- Si ninguna de las anteriores se cumple, devuelve error:
		ELSE 'Error'
	END
	
	-- Calcular días en base al parámetro de entrada @formato
	SELECT @dias = CASE
		-- Si @formato es W:
		-- Si la entrada es menor que un día OR si el resto de (entrada / una semana) es menor que un día OR si la entrada es múltiplo de una semana, devuelve null:
		WHEN (@formato = 'W') AND ((@inputSegundos < @unDia) OR (@inputSegundos % (@unaSemana) < @unDia) OR (@inputSegundos % (@unaSemana) = 0)) THEN NULL
		-- Si la entrada es más de una semana y el resultado de (entrada - (número de semanas * 7)) != 1, devuelve el número de días - (número de semanas * 7) + cadena en plural.
		-- Esta línea sirve para que si la entrada son 8 días, la salida final de esta función sea "1 semana, 1 día..." en lugar de "1 semana, 8 días...":
		WHEN (@formato = 'W') AND ((@inputSegundos >= @unaSemana) AND ((@inputSegundos - ((@inputSegundos / (@unaSemana)) * @unaSemana)) / @unDia) != 1) THEN CAST((@inputSegundos - ((@inputSegundos / (@unaSemana)) * (@unaSemana))) / @unDia AS VARCHAR(4)) + ' días'
		-- Si la entrada es dos o más días pero menos de una semana, devuelve el número de días + cadena en plural:
	    WHEN (@formato = 'W') AND (@inputSegundos >= @unDia * 2 AND @inputSegundos < @unaSemana) THEN CAST(@inputSegundos / @unDia AS VARCHAR(4)) + ' días'
		-- Si la entrada es un día o más pero menos de dos días OR si (entrada -(número de semanas * 7)) = 1, devuelve cadena en singular:
	    WHEN (@formato = 'W') AND ((@inputSegundos >= @unDia AND @inputSegundos < @unDia * 2) OR (((@inputSegundos - ((@inputSegundos / (@unaSemana)) * (@unaSemana))) / @unDia) = 1)) THEN '1 día'
		-- Si @formato es D:
		-- Si la entrada es dos o más días, devuelve el número de días + cadena en plural:
		WHEN (@formato = 'D') AND (@inputSegundos >= @unDia * 2) THEN CAST((@inputSegundos / @unDia) AS VARCHAR(4)) + ' días'
		-- Si la entrada es un día o más pero menos de dos días, devuelve cadena en singular:
		WHEN (@formato = 'D') AND (@inputSegundos >= @unDia) AND (@inputSegundos < @unDia * 2) THEN '1 día'
		-- Si la entrada es menor a un día, devuelve null:
		WHEN (@formato = 'D') AND (@inputSegundos < @unDia) THEN NULL
		-- Si ninguna de las anteriores se cumple, devuelve error:
		ELSE 'Error'
	END
	
	-- Calcular HH:MM:SS
	SELECT @hms = CASE
		-- Si la entrada no es múltiplo de un día, devuelve la cadena formateada:
		WHEN (@inputSegundos % @unDia != 0) THEN CONVERT(VARCHAR(8), DATEADD(SECOND, @inputSegundos, 0), 108)
		-- Si la entrada es exactamente un día OR si la entrada es múltimplo de un día, devuelve null:
	    WHEN (@inputSegundos = @unDia) OR (@inputSegundos % @unDia = 0) THEN NULL
		-- Si ninguna de las anteriores se cumple, devuelve error:
		ELSE 'Error'
	END

	-- Ésta última sentencia SELECT formatea la salida en base a los cálculos realizados previamente
	SELECT @cadenaFormateada = CASE
		-- No deberían aparecer errores en las sentencias anteriores, pero se capturan por si apareciesen.
		-- Si aparece un error calculando las semanas, devuelve error 1:
		WHEN @semanas = 'Error' THEN 'Error 1: fallo cálculo de semanas'
		-- Si aparece un error calculando los días, devuelve error 2:
		WHEN @dias = 'Error' THEN 'Error 2: fallo cálculo de días'
		-- Si aparece un error calculando HH:MM:SS, devuelve error 3:
		WHEN @hms = 'Error' THEN 'Error 3: fallo cálculo de HH:MM:SS'
	    -- Si la enrada es negativa, devuelve error 4:
	    WHEN (@inputSegundos < 0) THEN 'Error 4: valor negativo'
		-- Si la entrada es 0, devuelve 'Nada':
	    WHEN (@inputSegundos = 0) THEN 'Nada'
		-- Con semanas, días y tiempo:
	    WHEN (@semanas IS NOT NULL AND @dias IS NOT NULL AND @hms IS NOT NULL) THEN @semanas + ', ' + @dias + ', ' + @hms
		-- Con semanas y días, sin tiempo:
	    WHEN (@semanas IS NOT NULL AND @dias IS NOT NULL AND @hms IS NULL) THEN @semanas + ', ' + @dias
		-- Con semanas y tiempo, sin días:
	    WHEN (@semanas IS NOT NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @semanas + ', ' + @hms
		-- Con semanas, sin días ni tiempo:
	    WHEN (@semanas IS NOT NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @semanas
	    -- Sin semanas, con días y tiempo:
	    WHEN (@semanas IS NULL AND @dias IS NOT NULL AND @hms IS NOT NULL) THEN @dias + ', ' + @hms
		-- Sin semanas, con días y sin tiempo:
	    WHEN (@semanas IS NULL AND @dias IS NOT NULL AND @hms IS NULL) THEN @dias
		-- Sin semanas, con tiempo y sin días:
	    WHEN (@semanas IS NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @hms
		-- Siempre debería cumplirse una de las anteriores, pero por si algo falla el ELSE de momento es error 5:
		ELSE 'Error 5: revisar función'
	END
	-- Devuelve cadena formateada
	RETURN @cadenaFormateada
END