CREATE OR REPLACE FUNCTION kosten_fuss_f(
autostrassen float,
fuerFussgaenger float,
mittelFuerFussgaengerGeeignet float,
fahrradwege float,
unclassified float,
nichtKlar float) RETURNS void AS
$$
BEGIN
	UPDATE osm_way_classes SET kosten_fuss = $1 WHERE str_name IN (
	'motorway', 'motorway_link', 'motorway_junction', 'trunk',
	'trunk_link', 'primary', 'primary_link', 'secondary', 'tertiary',
	'bus_guideway', 'secondary_link', 'tertiary_link',
	'opposite', 'opposite_lane', 'roundabout', 'services', 'lane', 'cycleway');

	UPDATE osm_way_classes SET kosten_fuss = $2 WHERE str_name IN (
	'path', 'footway', 'pedestrian', 'track', 'living_street',
	'service', 'bridleway', 'byway', 'steps');

	UPDATE osm_way_classes SET kosten_fuss = $3 WHERE str_name IN (
	'residential', 'grade1', 'grade2', 'grade3', 'grade4', 'grade5');

	UPDATE osm_way_classes SET kosten_fuss = $4 WHERE str_name IN (
	'unclassified');

	UPDATE osm_way_classes SET kosten_fuss = $5 WHERE str_name IN (
	'road');
END
$$
language 'plpgsql';

SELECT kosten_fuss_f(999999.0, 1.0, 1.5, 1.0, 50.0);