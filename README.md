<h1> Studienprojekt </h1>

Beschreibung der Code Snippets und weiteren nötigen Dateien.
Verwendete Software: 

- `PostgreSQL`
- `PostGIS`
- `osm2pgrouting`
- `pgRouting`

Visualisierung: 

- `QGIS`

Entwicklungsumgebung: 

- `OSGeo-Live 10.0`

Datengrundlage: 

- `OpenstreetMap`

<h2> Herunterladen der Daten und erstellen der Topologie</h2>
Zum erstellen der Topologie mittels `osm2pgrouting folgendes ausführen (`bash Shell`)

Daten herunterladen mittels `xapi` von `OpenstreetMap`. 

    $ CITY="NEW_YORK"
    $ BBOX="-74.3500,40.4929,-73.5892,40.9343"
    $ wget --progress=dot:mega -O "$CITY.osm" "http://www.overpass-api.de/api/xapi?*[bbox=${BBOX}][@meta]"

    # datenbank vorbereiten
    $ psql -U user
    CREATE DATABASE nyc;
    \c nyc
    CREATE EXTENSION postgis;
    CREATE EXTENSION pgrouting;
    \q

    $ osm2pgrouting -f NEW_YORK.osm -c path/config.xml -d nyc -U user


<h3>..._config.xml</h3>
In der `XML Datei` befinden sich die Straßenklassen, welche zum erstellen der Topologie verwendet werden sollen. In `auto_config.xml` befinden sich ebenfalls Standardgeschwindigkeiten, falls keine Geschwindigkeiten in der Straßengeometrie auf OpenstreetMap eingetragen sind. Die `XML-Dateien` sind ein Mashup aus https://github.com/Project-OSRM/osrm-backend/tree/master/profiles, https://github.com/cvvergara/osm2pgrouting/tree/v3/develop und http://wiki.openstreetmap.org/wiki/Key:highway. Insgesamt wurden zwei Topologien zum Routing erstellt: Eine Topologie für FahrradfahrerInnen und eine Topologie für motorisierte Fahrzeuge.

<h2> SQL </h2>
<h3> daten_vorbereiten.sql</h3>
`osm2pgrouting` erstellt in der ways Tabelle eine Spalte mit dem namen "name". Das ist ein in `SQL` reserviertes Wort und wird deswegen umbenannt.

    ALTER TABLE ways RENAME COLUMN name TO str_name;
    ALTER TABLE osm_way_classes RENAME COLUMN name TO str_name;

Des Weiteren wird zu der von `osm2pgrouting` eine Kostenspalte (`cost`, `cost_s`, `reverse_cost` und `reverse_cost_s`) in der Tabelle mit allen Straßen/Wegen hinzugefügt. Sind diese `< 0` bzw. `> 0` bestimmt dies die Fahrtrichtung von Startknoten -> Zielknoten bzw. Zielknoten -> Startknoten. Hierrüber werden Einbahnstraßen definiert. Die von `osm2pgRouting` erstellte Spalte `reverse_cost` ist in Grad. Diese ist nicht verwendbar und muss in Meter umgewandelt werden. Die von `osm2pgRouting` erstellte Spalte `length_m` beinhaltet nicht die Informationen über die Fahrtrichtung (also `< 0` oder `> 0`). Aus diesem Grund müssen diese Spalten hinzugefügt werden. Hierbei darf nicht die Information über die Fahrtrichtung verloren gehen.

    ALTER TABLE ways ADD COLUMN reverse_cost_m DOUBLE PRECISION; 
    UPDATE ways SET reverse_cost_m = 
    CASE 
        WHEN reverse_cost < 0 THEN ST_Length(the_geom::geography) * (-1) 
        ELSE ST_Length(the_geom::geography)
    END;

    ALTER TABLE ways ADD COLUMN length_m_cost double precision;
    UPDATE ways SET length_m_cost = 
    CASE 
        WHEN cost <= 0 THEN length_m * (-1) 
        ELSE length_m
    END;


<h3> fahrrad_routing.sql / auto_weg_routing.sql / auto_zeit_routing.sql </h3>
Das eigentliche Routing geschieht in diesen Dateien. Zum Fahrradrouting wird die Topologie verwendet, welche mit der `fahrrad_config.xml` erstellt wurde. Zum auffinden des schnellsten- und kürzesten Weges mit motorisierten Fahrzeugen wird die Topologie verwendet, welche mit `auto_config.xml` erstellt wurde. 

<h3>service_areas.sql</h3>
Die Funktion `catchment_areas_polygons_f()` wurde selber geschrieben. Sie vereinigt zwei `pgRouting` Funktionen, `pgr_drivingdistance()` und `pgr_pointsAsPolygon()` und automatisiert das erstellen der Polygone für Service Areas. Die native `pgr_pointsAsPolygon()` Funktion zeichnet lediglich ein Polygon. Falls in einer Abbildung mehrere Erreichbarkeiten, also die Erreichbarkeit in 60s, 120s, ... ns entfernt abgebildet werden sollten, müsste die Funktion n mal ausführen. Nicht nur das. Es müssten und jedes mal die Eingabeparameter geändern werden. Die hier geschriebene Funktion führt dies automatisch aus. Sie benötigt vier Parameter

- `start_lon (numeric)`: Längengrad des Punktes, um welchen die Service Areas bestimmt werden sollen
- `start_lat (numeric)`: Breitengrad des Punktes, um welchen die Service Areas bestimmt werden sollen
- `fahrtzeit_s (integer)`: Wie weit soll der am weitesten entfernte Punkt (in Sekunden) vom Zentrum der Service Areas (also start_lon/start_lat) entfernt sein?
- `isolinien_s`: In welchen Schritten/Abständen (in Sekunden) sollen die Isolinien eingezeichnet werden. 

Die Funktion zeichnet keine wirklichen Isolinien. Sie gibt stattdessen für jeden Schritt, z.B. 60s, 120s, ... ein Polygon zurück. So kann identifiziert werden, welche Punkte innerhalb des Polygones liegen und somit erreichbar sind. 


<h2> Alternative Vorgehensweise am Beispiels schnellster Weg </h2>
Das Routing soll nur auf geeigneten Straßen erfolgen. Dafür müssen entsprechende Straßenklassen identifiziert werden und Kosten für diese festgelgt werden.

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
Alle Wege, welche beispielsweise nicht designierte Fußwege sind, bekommen sehr hohe Kosten. Feiner Abstufungen bei Wegen welche für beispielsweise FußgängerInnen zwar geeignet sind, aber eher suboptimal. Das ganz wird in eine Funktion gewrapped welche später im `ALIAS` der `cost` bzw. `reverse_cost` verwendet wird. 

    CREATE OR REPLACE FUNCTION kosten_auto_zeit_f(
    strKlassen text)
    RETURNS double precision AS
    $$
    BEGIN
    CASE 
        WHEN $1 IN ('motorway', 'motorway_link', 'motorway_junction', 'trunk',
        'trunk_link', 'primary', 'primary_link', 'secondary', 'tertiary', 
        'bus_guideway', 'secondary_link', 'tertiary_link', 'opposite', 
        'opposite_lane', 'roundabout', 'services', 'living_street', 
        'service', 'bridleway', 'byway', 'residential', 'lane') 
        THEN RETURN 1.0;

        WHEN $1 IN ('path', 'footway', 'pedestrian', 'track', 'steps', 
        'cycleway') THEN RETURN -1.0;
    
        WHEN $1 IN ('grade1') THEN RETURN 6.2;

        WHEN $1 IN ('grade2') THEN RETURN 6.4;

        WHEN $1 IN ('grade3') THEN RETURN 6.6;

        WHEN $1 IN ('grade4') THEN RETURN 6.8;

        WHEN $1 IN ('grade5') THEN RETURN 8.0;

        WHEN $1 IN ('unclassified') THEN RETURN -1.0;

        ELSE RETURN 5.0; -- 'road'

    END CASE;
    END;
    $$
    language 'plpgsql';


Es wird überprüft, ob die Straßenklasse des Weges eine der Straßenkasen im `array` ist. Ist dies der Fall, so wir der entsprechende Kostenfaktor zurückgegeben.
Beim Routing wurden dann die selbst erstellten Kostenfaktoren mit der Länge des Straßensegmentes bzw. der Zeit, welche benötigt wird, um dieses Segment zu passieren, multipliziert. Hieraus resultiert der beste Weg, abhängig von den Kosten. 


    SELECT route.*, w.the_geom, w.length_m FROM pgr_dijkstra('
        SELECT gid AS id,
            source,
            target,
            CASE 
                WHEN cost_s < 0 THEN cost_s 
                ELSE kosten_auto_zeit_f(w.str_name) * cost_s 
            END AS cost,
            CASE 
                WHEN reverse_cost_s < 0 THEN reverse_cost_s 
                ELSE kosten_auto_zeit_f(w.str_name) * reverse_cost_s 
            END AS reverse_cost
            FROM ways w
            JOIN osm_way_classes owc
            ON w.class_id = owc.class_id',
            pgr_pointToEdgeNode('ways', ST_SetSRID(
                    ST_Point(-73.930397, 40.783351), 
                    4326), 0.01
                ), 
            pgr_pointToEdgeNode('ways', ST_SetSRID(
                    ST_Point(-73.882022, 40.852214), 
                    4326), 0.01),
            directed := true) AS route
    LEFT JOIN ways w
    ON route.edge = w.gid
    ORDER BY seq;

Das Verwenden der Kostenfunktion und die Implementation als `ALIAS` findet in folgenden Zeilen statt.

    CASE 
        WHEN cost_s < 0 THEN cost_s 
        ELSE kosten_auto_zeit_f(w.str_name) * cost_s 
    END AS cost, -- ALIAS Zuweisung
    CASE 
        WHEN reverse_cost_s < 0 THEN reverse_cost_s 
        ELSE kosten_auto_zeit_f(w.str_name) * reverse_cost_s 
    END AS reverse_cost -- ALIAS Zuweisung

Das Prüfen auf `< 0` und `> 0` ist nötig, um die Fahrtrichtung von Startknoten -> Zielknoten (`cost`) bzw. vom Zielknoten -> Startknoten (`reverse_cost`) zu bestimmen. 

