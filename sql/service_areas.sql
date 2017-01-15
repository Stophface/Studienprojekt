CREATE OR REPLACE FUNCTION catchment_areas_polygons_f(start_lon numeric, start_lat numeric,
fahrtzeit_s integer, isolinien_s integer)
RETURNS void AS
$$
DECLARE
	schritte integer := $4;
BEGIN

	-- Tabelle fuer die nodes
	CREATE TEMPORARY TABLE catchment_nodes
	(
		seq integer,
		node bigint,
		cost double precision,
		agg_cost double precision,
		the_geom geometry
	) ON COMMIT DROP;

	-- Tabelle fuer unsortierte Polygone
	CREATE TEMPORARY TABLE catchment_polygons
	(
		geom geometry,
		schritte integer
	) ON COMMIT DROP;

	-- Erreichbaren Nodes bestimmen
	-- und in temporaerer Tabelle schreiben
	INSERT INTO catchment_nodes
		SELECT dd.seq, dd.node, dd.cost, dd.agg_cost,
		ST_SetSRID(
			ST_Point(
				ST_X(wvp.the_geom),
				ST_Y(wvp.the_geom)), 4326
			) AS the_geom
		FROM pgr_drivingdistance('
		SELECT gid AS id,
			source,
			target,
			cost_s * kosten_auto_zeit AS cost,
			reverse_cost_s AS reverse_cost
		FROM ways
		JOIN osm_way_classes
		ON ways.class_id = osm_way_classes.class_id',
			pgr_pointToEdgeNode('ways', ST_SetSRID(
				ST_Point($1, $2),
				4326), 0.01
			),
			$3,
			directed := true) AS dd INNER JOIN
				ways_vertices_pgr
				AS wvp
				ON dd.node = wvp.id;

	-- Polygone um die Punkte zeichnen
	-- und in temporaere Tabelle schreiben 
	WHILE $4 <= $3 LOOP
		INSERT INTO catchment_polygons
			SELECT ST_SetSRID(
					pgr_pointsAsPolygon(
					'SELECT cnt.seq AS id,
					ST_X(cnt.the_geom) AS x,
					ST_Y(cnt.the_geom) AS y
					FROM catchment_nodes cnt
					WHERE cnt.agg_cost <= ' || $4), 4326
				) AS geom, $4 AS schritte;
		$4 := $4 + schritte;
	END LOOP;

	-- die Reihenfolge der Polygone ist falsch
	-- die großen liegen oben, die kleinen unten
	-- deswegen von klein nach groß sortieren 
	-- und in finale tabelle schreiben
	CREATE TABLE catchment_areas AS
		SELECT DISTINCT(cp.schritte), cp.geom
		FROM catchment_polygons cp
		ORDER BY cp.schritte DESC;

END
$$
language 'plpgsql';

SELECT * FROM catchment_areas_polygons_f(-73.882022, 40.852214, 600, 60);