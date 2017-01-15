<h1> Studienprojekt </h1>

Beschreibung der einzelnen SQL Scripte.

<h2> Topologie</h2>
-> xml datei
-> command line code

<h2> SQL </h2>
<h3> daten_vorbereiten</h3>
osm2pgrouting erstellt in der ways Tabelle eine Spalte mit dem namen "name". Das ist ein in SQL reserviertes Wort und wird deswegen umbenannt.
Des Weiteren wird zu der von osm2pgrouting eine Kostenspalte hinzugefügt. In diese werden später die Kostenfaktoren eingetragen, mit welcher der Algorithmus rechnet. Man könnte Alternativ auch eine Kostenfunktion schreiben, wie beispielsweise:

    CREATE OR REPLACE FUNCTION kosten_f(straßenklasse text, kosten double precision)
    RETURNS integer AS
    $$
    SELECT CASE
	    WHEN $1 IN (...)
	    THEN kosten
	    WHEN $1 IN (...)
	    THEN 2
	    ....
	    ELSE 9999
	    END
    $$
    language 'sql';

Die Funktion würde wie folgt verwendet werden

    CREATE TABLE route_ AS
    SELECT route.*, w.the_geom, w.length_m FROM pgr_dijkstra('
        SELECT gid AS id,
            source,
            target,
	        kosten(str_name, cost_s) AS cost, -- Verwendung der Kostenfunktion
            reverse_cost_s AS reverse_cost
        FROM ways',
        pgr_pointToEdgeNode('ways', ST_SetSRID(
					ST_Point(-73.930397, 40.783351),
					4326), 0.01
			),
		pgr_pointToEdgeNode('ways', ST_SetSRID(
					ST_Point(-73.882022, 40.852214),
					4326), 0.01),
		directed := false) AS route
    LEFT JOIN ways w
    ON route.edge = w.gid
    ORDER BY seq;


Das ist aber rechenintensiver da diese Funktion jedes mal beim Ausführen des Routingalogrithmusses ausgeführt werden muss. Wenn die Kosten direkt in die Tabelle geschrieben werden, müssen diese nur einmal berechnet werden. Über einen Join können den einzelnen Straßen dann beim Routing die Kostenfaktoren zugeordnet werden. Joins sind in relationalen Datenbanken sehr schnell und deswegen zu bevorzugen.


<h3>kosten_fuss / kosten_auto_weg / kosten_auto_zeit</h3>
Das Routing soll nach Möglichkeit auf designierten Fußwegen erfolgen. Dafür müssen entsprechende Straßenklassen identifiziert werden und Kosten für diese festgelgt werden.

Die im Datensatz vorhanden Straßenklassen wurden mit

    SELECT * FROM osm_way_classes ORDER BY class_id;

ermittelt. 

    "road", "motorway", "motorway_link", "motorway_junction", "trunk",
    "trunk_link" ,"primary", "primary_link", "secondary", "tertiary"
    "residential", "living_street", "service", "track", "pedestrian",
    "services", "bus_guideway", "path", "cycleway", "footway",
    "bridleway", "byway", "steps", "unclassified", "secondary_link",
    "tertiary_link", "lane", "track", "opposite_lane", "opposite",
    "grade1", "grade2", "grade3", "grade4", "grade5", "roundabout"

Beschreibungen der Straßenklassen kann auf http://wiki.openstreetmap.org/wiki/Key:highway nachgelesen werden.
Alle Wege, welche beispielsweise nicht designierte Fußwege sind, bekommen sehr hohe Kosten. Feiner Abstufungen bei Wegen welche für beispielsweise FußgängerInnen zwar geeignet sind, aber eher suboptimal. Das ganz wird in eine Funktion verpackt. Besonders hervor zu heben ist, dass ab pgRouting 2.1.x Straßen, welche aus dem Routing ausgeschlossen werden sollen (wie z.B. Autobahnen für FußgängerInnen) nicht mehr mit -1, sondern mit sehr hohen Zahlen bepreist werden. 
Für die Aufschlüsselung der Kosten siehe kosten_routing.jpg

<h3> fuss_routing / auto_weg_routing / auto_zeit_routing </h3>
Das eigentliche Routing geschieht in diesen Dateien. Beim Routing für FußgängerInnen wurden die selbst erstellten Kostenfaktoren mit der Länge des Straßensegmentes multipliziert. Hieraus resultiert der kürzeste Weg. Dies gilt ebenfalls für das Routing mit motorisierten Fahrzeugen (kürzeste Strecke). Beim Routing für motorisierte Fahrzeuge, wo es gilt den schnellsten Weg zu finden, wurde die Zeit, welche es benötigt das Straßensegment bei gegebener Maximalgeschwindigkeit zu befahren, mit den Kostenfaktoren multipliziert.
Die entsprechende Zeile im Code ist:
	
	[...]
    length_m * kosten_fuss AS cost
    [...]











