-- Crear funci�n FN_EPOCH_A_DURACION (@entradas y TIPOS) DEVUELVE salida(LONGITUD)
CREATE FUNCTION FN_EPOCH_A_DURACION (@formato CHAR(1), @inputSegundos INT) RETURNS VARCHAR(28) AS
BEGIN
	-- Las variables son de longitud variable (VARCHAR en lugar de CHAR) de manera que la salida
	-- no est� llena de espacios vac�os y la cadena tenga un formato correcto.
	DECLARE @semanas VARCHAR(10)
	DECLARE @dias VARCHAR(10)
	DECLARE @hms VARCHAR(8)
	DECLARE @cadenaFormateada VARCHAR(35)

	-- Para facilitar la lectura, se declaran variables que contienen el n�mero de segundos
	-- en una semana y en un d�a, se usar�n para los c�lculos siempre que sea posible.
	DECLARE @unaSemana INT = 604800
	DECLARE @unDia INT = 86400

	/* Cada una de las siguientes tres sentencias SELECT contiene una expresi�n CASE que establece
	un valor en cada una de las tres primeras variables que se definen en esta funci�n. El formato
	var�a en funci�n del par�metro de entrada @formato que se reciba, de la siguiente manera:
	- "W" (de Weeks) devolver� el resultado en formato: "SS Semanas, DD d�as, HH:MM:SS"
	- "D" (de D�as) lo devolver� as�: "DD d�as, HH:MM:SS" 

	Las expresiones CASE causan break tras leer una condici�n true, de modo que el orden de las lineas 
	es importante en algunos casos. Por ejemplo, la primera SELECT tiene un CASE con tres posibles 
	opciones. Si movemos la primera de ellas abajo del todo, una de las otras se cumplir� primero y 
	llamar a esta funci�n con la opci�n "D" en el primer par�metro no funcionar� correctamente */

	-- Calcular semanas
	SELECT @semanas = CASE
		-- Si @formato es D o la entrada es menos de una semana, devuelve null.
		WHEN @formato = 'D' OR (@inputSegundos < @unaSemana) THEN NULL
		-- Si la entrada es dos o m�s semanas, devuelve el n�mero de semanas + cadena en plural
	    WHEN (@inputSegundos >= @unaSemana * 2) THEN CAST((@inputSegundos / @unaSemana) AS VARCHAR(4)) + ' semanas'
		-- Si la entrada es una semana o m�s pero menos de dos semanas, devuelve una cadena en singular:
		WHEN (@inputSegundos >= @unaSemana AND @inputSegundos < (@unaSemana * 2)) THEN '1 semana'
		-- Si ninguna de las anteriores se cumple, devuelve error:
		ELSE 'Error'
	END
	
	-- Calcular d�as en base al par�metro de entrada @formato
	SELECT @dias = CASE
		-- Si @formato es W:
		-- Si la entrada es menor que un d�a OR si el resto de (entrada / una semana) es menor que un d�a OR si la entrada es m�ltiplo de una semana, devuelve null:
		WHEN (@formato = 'W') AND ((@inputSegundos < @unDia) OR (@inputSegundos % (@unaSemana) < @unDia) OR (@inputSegundos % (@unaSemana) = 0)) THEN NULL
		-- Si la entrada es m�s de una semana y el resultado de (entrada - (n�mero de semanas * 7)) != 1, devuelve el n�mero de d�as - (n�mero de semanas * 7) + cadena en plural.
		-- Esta l�nea sirve para que si la entrada son 8 d�as, la salida final de esta funci�n sea "1 semana, 1 d�a..." en lugar de "1 semana, 8 d�as...":
		WHEN (@formato = 'W') AND ((@inputSegundos >= @unaSemana) AND ((@inputSegundos - ((@inputSegundos / (@unaSemana)) * @unaSemana)) / @unDia) != 1) THEN CAST((@inputSegundos - ((@inputSegundos / (@unaSemana)) * (@unaSemana))) / @unDia AS VARCHAR(4)) + ' d�as'
		-- Si la entrada es dos o m�s d�as pero menos de una semana, devuelve el n�mero de d�as + cadena en plural:
	    WHEN (@formato = 'W') AND (@inputSegundos >= @unDia * 2 AND @inputSegundos < @unaSemana) THEN CAST(@inputSegundos / @unDia AS VARCHAR(4)) + ' d�as'
		-- Si la entrada es un d�a o m�s pero menos de dos d�as OR si (entrada -(n�mero de semanas * 7)) = 1, devuelve cadena en singular:
	    WHEN (@formato = 'W') AND ((@inputSegundos >= @unDia AND @inputSegundos < @unDia * 2) OR (((@inputSegundos - ((@inputSegundos / (@unaSemana)) * (@unaSemana))) / @unDia) = 1)) THEN '1 d�a'
		-- Si @formato es D:
		-- Si la entrada es dos o m�s d�as, devuelve el n�mero de d�as + cadena en plural:
		WHEN (@formato = 'D') AND (@inputSegundos >= @unDia * 2) THEN CAST((@inputSegundos / @unDia) AS VARCHAR(4)) + ' d�as'
		-- Si la entrada es un d�a o m�s pero menos de dos d�as, devuelve cadena en singular:
		WHEN (@formato = 'D') AND (@inputSegundos >= @unDia) AND (@inputSegundos < @unDia * 2) THEN '1 d�a'
		-- Si la entrada es menor a un d�a, devuelve null:
		WHEN (@formato = 'D') AND (@inputSegundos < @unDia) THEN NULL
		-- Si ninguna de las anteriores se cumple, devuelve error:
		ELSE 'Error'
	END
	
	-- Calcular HH:MM:SS
	SELECT @hms = CASE
		-- Si la entrada no es m�ltiplo de un d�a, devuelve la cadena formateada:
		WHEN (@inputSegundos % @unDia != 0) THEN CONVERT(VARCHAR(8), DATEADD(SECOND, @inputSegundos, 0), 108)
		-- Si la entrada es exactamente un d�a OR si la entrada es m�ltimplo de un d�a, devuelve null:
	    WHEN (@inputSegundos = @unDia) OR (@inputSegundos % @unDia = 0) THEN NULL
		-- Si ninguna de las anteriores se cumple, devuelve error:
		ELSE 'Error'
	END

	-- �sta �ltima sentencia SELECT formatea la salida en base a los c�lculos realizados previamente
	SELECT @cadenaFormateada = CASE
		-- No deber�an aparecer errores en las sentencias anteriores, pero se capturan por si apareciesen.
		-- Si aparece un error calculando las semanas, devuelve error 1:
		WHEN @semanas = 'Error' THEN 'Error 1: fallo c�lculo de semanas'
		-- Si aparece un error calculando los d�as, devuelve error 2:
		WHEN @dias = 'Error' THEN 'Error 2: fallo c�lculo de d�as'
		-- Si aparece un error calculando HH:MM:SS, devuelve error 3:
		WHEN @hms = 'Error' THEN 'Error 3: fallo c�lculo de HH:MM:SS'
	    -- Si la enrada es negativa, devuelve error 4:
	    WHEN (@inputSegundos < 0) THEN 'Error 4: valor negativo'
		-- Si la entrada es 0, devuelve 'Nada':
	    WHEN (@inputSegundos = 0) THEN 'Nada'
		-- Con semanas, d�as y tiempo:
	    WHEN (@semanas IS NOT NULL AND @dias IS NOT NULL AND @hms IS NOT NULL) THEN @semanas + ', ' + @dias + ', ' + @hms
		-- Con semanas y d�as, sin tiempo:
	    WHEN (@semanas IS NOT NULL AND @dias IS NOT NULL AND @hms IS NULL) THEN @semanas + ', ' + @dias
		-- Con semanas y tiempo, sin d�as:
	    WHEN (@semanas IS NOT NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @semanas + ', ' + @hms
		-- Con semanas, sin d�as ni tiempo:
	    WHEN (@semanas IS NOT NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @semanas
	    -- Sin semanas, con d�as y tiempo:
	    WHEN (@semanas IS NULL AND @dias IS NOT NULL AND @hms IS NOT NULL) THEN @dias + ', ' + @hms
		-- Sin semanas, con d�as y sin tiempo:
	    WHEN (@semanas IS NULL AND @dias IS NOT NULL AND @hms IS NULL) THEN @dias
		-- Sin semanas, con tiempo y sin d�as:
	    WHEN (@semanas IS NULL AND @dias IS NULL AND @hms IS NOT NULL) THEN @hms
		-- Siempre deber�a cumplirse una de las anteriores, pero por si algo falla el ELSE de momento es error 5:
		ELSE 'Error 5: revisar funci�n'
	END
	-- Devuelve cadena formateada
	RETURN @cadenaFormateada
END