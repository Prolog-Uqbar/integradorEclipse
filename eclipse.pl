eclipse(arrecifes, buenosAires, horario(17, 44), 2.5, duracion(0, 40)).
eclipse(bellaVista, sanJuan, horario(17, 41), 11.5, duracion(2, 27)).
eclipse(carmenDeAreco, buenosAires, horario(17, 44), 2.1, duracion(1, 30)).
eclipse(chacabuco, buenosAires, horario(17, 43), 2.6, duracion(2, 7)).
eclipse(chepes, laRioja, horario(17, 42), 8.9, duracion(2, 3)).
eclipse(ezeiza, buenosAires, horario(17, 44), 0.9, duracion(1, 1)).
eclipse(jachal, sanJuan, horario(17, 41), 11.1, duracion(1, 39)).
eclipse(pergamino, buenosAires, horario(17, 44), 2.9, duracion(0, 56)).
eclipse(quines, sanLuis, horario(17, 42), 7.8, duracion(2, 13)).
eclipse(rodeo, sanJuan, horario(17, 41), 11.5, duracion(2, 16)).
eclipse(rioCuarto, cordoba, horario(17, 42), 6.3, duracion(1, 54)).
eclipse(venadoTuerto, santaFe, horario(17, 43), 4.1, duracion(2, 11)).
eclipse(merlo, sanLuis, horario(17, 42), 7.1, duracion(2, 19)).

% La estrategia elegida es mantener el detalle de la información original usando functores para horario y duración
% El horario se mantiene en toda la solucion como functor
% La duración se la convierte a segundos para aprovechar los predicados numéricos existentes (sumlist, <)

% En la solución se usa este predicado en vez de los hechos, para ya tener la duración expresada en segundos
seVeElEclipse(Ciudad, Provincia, Horario, Altura, Duracion):-
    eclipse(Ciudad, Provincia, Horario, Altura,  DuracionOriginal),
    conversionSegundos(DuracionOriginal, Duracion).

% Conversiones de unidades de medida de tiempo, para pasar de minutos y segundos a segundos (y viceversa)
conversionSegundos(duracion(Minutos, Segundos), SegundosTotales):-
    SegundosTotales is Minutos * 60 + Segundos.

conversionMinutos(duracion(Minutos, Segundos), SegundosTotales):-
    Minutos is SegundosTotales div 60,
    Segundos is SegundosTotales mod 60.


% Basta con definir hechos sueltos, no justifica usar listas.
servicio(bellaVista, telescopio).
servicio(chepes, telescopio).
servicio(ezeiza, telescopio).
servicio(chacabuco, reposeraPublica).
servicio(arrecifes, reposeraPublica).
servicio(chepes, reposeraPublica).
servicio(venadoTuerto, reposeraPublica).
servicio(quines, observatorioAstronomico).
servicio(quines, lentesDeSol).
servicio(rodeo, lentesDeSol).
servicio(rioCuarto, lentesDeSol).
servicio(merlo, lentesDeSol).

% 1. Los lugares donde la altura del sol es más de 10º o empieza después de las 17:42.
buenLugar(Ciudad):-
    seVeElEclipse(Ciudad, _, _, Altura, _),
    Altura > 10.

buenLugar(Ciudad):-
    seVeElEclipse(Ciudad, _, Horario, _, _),
    horarioLimite(HorarioLimite),
    mayor(Horario, HorarioLimite).

horarioLimite(horario(17,42)).

% Si la hora es mayor se deduce que el horario es mayor, sin comparar minutos.
mayor(horario(HoraA, _), horario(HoraB, _)):-
    HoraA > HoraB.
% En la mima hora, el horario es mayor cuando los minutos son mayores.
mayor(horario(Hora, MinutosA), horario(Hora, MinutosB)):-
    MinutosA > MinutosB.

% 2. Los lugares que no tienen ningún servicio.
lugaresSinServicios(Ciudad):-
    seVeElEclipse(Ciudad, _, _, _, _),
    not(servicio(Ciudad, _)).

% 3. Las provincias que tienen un sola ciudad donde verlo.
% Solucion con not "Se ve en una ciudad de la provincia y no se ve en otra ciudad de la provincia"
visibleEnUnaSolaCiudad(Provincia):-
    seVeElEclipse(CiudadA, Provincia, _, _, _),
    not((
        seVeElEclipse(CiudadB, Provincia, _, _, _),
        CiudadA \= CiudadB
    )).

% Solucion con forall "Se ve en una ciudad de la provincia y toda ciudad de la provincia en la que se ve, es la misma"

visibleEnUnaSolaCiudad(Provincia):-
    seVeElEclipse(CiudadA, Provincia, _, _, _),
    forall(
        seVeElEclipse(CiudadB, Provincia, _, _, _),
        CiudadA == CiudadB
    ).

% 4. El lugar donde dura más.
% solucion con forall "Una ciudad cuya duración, es mayor (o igual) que las duraciones de todas las ciudades "
lugarMasDuradero(Ciudad):-
    seVeElEclipse(Ciudad, _, _, _, Duracion),
    forall(
        seVeElEclipse(_, _, _, _, OtraDuracion),
        Duracion >= OtraDuracion
% variante con >, verificando que sea una ciudad diferente
%        (seVeElEclipse(OtraCiudad, _, _, _, OtraDuracion), Ciudad \= OtraCiudad),
%        Duracion > OtraDuracion
    ).

% solucion con not "Una ciudad para cuya duración, no existe otra duración de alguna ciudad que la supere"

lugarMasDuradero(Ciudad):-
    seVeElEclipse(Ciudad, _, _, _, Duracion),
    not((
        seVeElEclipse(_, _, _, _, OtraDuracion),
        OtraDuracion > Duracion
    )).

% 5.a. La duración promedio del eclipse en todo el pais
duracionPromedioPais(Promedio):-
    findall(
        Duracion,
        seVeElEclipse(_, _, _, _, Duracion),
        Duraciones
    ),
    promedioDuracion(Duraciones, Promedio).

% 5.b. La duración promedio del eclipse en cada provincia
duracionPromedioProvincia(Provincia, Promedio):-
    seVeElEclipse(_, Provincia, _, _, _),
    findall(
        Duracion,
        seVeElEclipse(_, Provincia, _, _, Duracion),
        Duraciones
    ),
    promedioDuracion(Duraciones, Promedio).

% 5.c. La duración promedio del eclipse entre las ciudades que tienen telescopio
duracionPromedioCiudadesConTelescopio(Promedio):-
    findall(
        Duracion,
        ( servicio(Ciudad, telescopio), seVeElEclipse(Ciudad, _, _, _, Duracion) ),
        Duraciones
    ),
    promedioDuracion(Duraciones, Promedio).


% Poniendo acá la conversión a minutos se expresa la duracion promedio con el mismo formato que los hechos
promedioDuracion(Duraciones, Promedio):-
    promedio(Duraciones, PromedioSeg),
    conversionMinutos(Promedio, PromedioSeg).

% Este predicado es genérico, no solo funciona con functores duración, sino que resuelve cualquier promedio.
promedio(Lista, Promedio):-
    sumlist(Lista, Sumatoria),
    length(Lista, Longitud),
    Promedio is Sumatoria div Longitud.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Variante convirtiendo el functor horario en minutos. 
%% Se usa el > en vez de definir una predicado mayor
%% pero hay que hacer el predicado conversionHorario.

buenLugar2(Ciudad):-
    seVeElEclipse(Ciudad, _, Horario, _, _),
    horarioLimite2(HorarioLimite),
    Horario > HorarioLimite.

horarioLimite2(Horario):-
    conversionHorario(horario(17,42), Horario).

conversionHorario(horario(Horas, Minutos), MinutosTotales):-
    MinutosTotales is Horas * 60 + Minutos.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Variante convirtiendo el functor duracion en segundos, sólo para hacer el promedio. 
%% Se deberia cambiar seVeElEclipse por eclipse,
%% en los predicados donde se usa el  >, reemplazarlo por mayorDuracion (Similar para el >=)
mayorDuracion(DuracionA, DuracionB):-
    conversionSegundos(DuracionA, SegundosA),
    conversionSegundos(DuracionB, SegundosB),
    SegundosA > SegundosB.
%% O hacer el predicado con estrategia similar al mayor de los horarios

%% y reemplazar promedio duracion por este predicado 
promedioDuracion2(Duraciones, Promedio):-
    findall(Segundos,(member(Duracion,Duraciones),conversionSegundos(Duracion,Segundos)),DuracionesSeg),
    promedio(DuracionesSeg, PromedioSeg),
    conversionMinutos(Promedio,PromedioSeg).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Variante con un mismo predicado para los promedios, con parametros para provincia, país o telescopio

duracionPromedioEclipse(pais,Promedio):-
    findall(
        Duracion,
        seVeElEclipse(_, _, _, _, Duracion),
        Duraciones
    ),
    promedioDuracion(Duraciones, Promedio).

duracionPromedioEclipse(Provincia, Promedio):-
    seVeElEclipse(_, Provincia, _, _, _),
    findall(
        Duracion,
        seVeElEclipse(_, Provincia, _, _, Duracion),
        Duraciones
    ),
    promedioDuracion(Duraciones, Promedio).

duracionPromedioEclipse(telescopio,Promedio):-
    findall(
        Duracion,
        ( servicio(Ciudad, telescopio), seVeElEclipse(Ciudad, _, _, _, Duracion) ),
        Duraciones
    ),
    promedioDuracion(Duraciones, Promedio).

%% Variante para cualquier servicio, se genera Servicio para que llegue unificado al findall
duracionPromedioEclipse(Servicio,Promedio):-
    servicio(_,Servicio),
    findall(
        Duracion,
        ( servicio(Ciudad, Servicio), seVeElEclipse(Ciudad, _, _, _, Duracion) ),
        Duraciones
    ),
    promedioDuracion(Duraciones, Promedio).


% Analizar la inversibilidad de los predicados del item 2 y 5. Justificar.

%   2)  lugaresSinServicios es inversible porque admite que la variable Ciudad esté libre,
%       es decir, que el motor de prolog pueda inferir y generar los valores que hacen 
%       válida la relacion.
%
%       Esto se logra mediante el predicado seVeElEclipse que funciona como generador de todas las 
%       ciudades donde puede verse el eclipse.
%       
%       De esta forma, la variable Ciudad llega ligada al not, pudiendo verificar si tal
%       ciudad (previamente generada) tiene algún servicio o no.
%
%   5)  
%       a. duracionPromedioPais es inversible. Se puede consultar con la variable Promedio sin ligar,
%          y se obtiene el mismo valor que si se lo pasara como parametro en la consulta daría true.
%
%       b. duracionPromedioProvincia es inversible para ambos parametros, 
%          el promedio, de igual manera que el caso anterior.
%          Para que sea inversible la Provincia, se unifica dicha variable previo al findall, 
%          es decer, se genera la provincia. 
%          De esta manera, se obtiene las duraciones de cualquier ciudad de esa provincia.
%
%       c. duracionPromedioCiudadesConTelescopio es inversible. Se puede consultar con Promedio como incognita,
%          similar al item a. 