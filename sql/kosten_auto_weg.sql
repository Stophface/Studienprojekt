CREATE OR REPLACE FUNCTION kosten_auto_weg_f(
spezielleAutostrassen float,
nichtFuerAutosGeeignet float,
schlechtfuerAutosGeeignet float,
schwerBefahrbar float,
unclassified float,
nichtKlar float) RETURNS void AS
$$
BEGIN
	UPDATE osm_way_classes SET kosten_auto_weg = $1 WHERE str_name IN (
	'motorway', 'motorway_link', 'motorway_junction', 'trunk',
	'trunk_link', 'primary', 'primary_link', 'secondary', 'tertiary',
	'bus_guideway', 'secondary_link', 'tertiary_link', 'opposite',
	'opposite_lane', 'roundabout', 'services', 'residential', 'lane');

	UPDATE osm_way_classes SET kosten_auto_weg = $2 WHERE str_name IN (
	'path', 'footway', 'pedestrian', 'track', 'cycleway', 'steps');

	UPDATE osm_way_classes SET kosten_auto_weg = $3 WHERE str_name IN (
	'living_street', 'service', 'bridleway', 'byway', 'grade1');

	UPDATE osm_way_classes SET kosten_auto_weg = $4 WHERE str_name IN (
	'grade2', 'grade3', 'grade4', 'grade5');

	UPDATE osm_way_classes SET kosten_auto_weg = $5 WHERE str_name IN (
	'unclassified');

	UPDATE osm_way_classes SET kosten_auto_weg = $6 WHERE str_name IN (
	'road');
END
$$
language 'plpgsql';

SELECT kosten_auto_weg_f(1.0, 999999.0, 2.0, 6.0, 999999.0, 1.5);
