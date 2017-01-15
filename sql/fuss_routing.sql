CREATE TABLE route_fuss AS
SELECT route.*, w.the_geom, w.length_m FROM pgr_dijkstra('
   SELECT gid AS id,
        source,
        target,
        length_m * kosten_fuss AS cost
    FROM ways
    JOIN osm_way_classes
    ON ways.class_id = osm_way_classes.class_id',
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