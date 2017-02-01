SELECT route.*, w.the_geom, w.length_m FROM pgr_dijkstra(
    $$
    SELECT gid AS id,
         source,
         target,
         length_m_cost AS cost,
         reverse_cost_m AS reverse_cost
     FROM ways w
     JOIN osm_way_classes owc
     ON w.class_id = owc.class_id
     $$,
    pgr_pointToEdgeNode('ways', ST_SetSRID(
					ST_Point(-73.9309012, 40.78293250), 
					4326), 0.01
			), 
    pgr_pointToEdgeNode('ways', ST_SetSRID(
					ST_Point(-73.98741310, 40.77359400), 
					4326), 0.01),
    directed := true) AS route
LEFT JOIN ways w
ON route.edge = w.gid
ORDER BY seq;
