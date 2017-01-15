CREATE OR REPLACE FUNCTION kosten_auto_zeit_f(
zeitAusGeschwindigkeitsbegrenzung float,
nichtFuerAutosGeeignet float,
strassenQualitaetAsphalt float,
strassenQualitaetStein float,
strassenQualitaetStarkVerdichteErde float,
strassenQualitaetLeichtVerdichteErde float,
strassenQualitaetGras float,
unclassified float,
nichtKlar float) RETURNS void AS
$$
BEGIN
	UPDATE osm_way_classes SET kosten_auto_zeit = $1 WHERE str_name IN (
	'motorway', 'motorway_link', 'motorway_junction', 'trunk',
	'trunk_link', 'primary', 'primary_link', 'secondary', 'tertiary',
	'bus_guideway', 'secondary_link', 'tertiary_link',
	'opposite', 'opposite_lane', 'roundabout', 'services',
	'living_street', 'service', 'bridleway', 'byway', 'residential', 'lane');

	UPDATE osm_way_classes SET kosten_auto_zeit = $2 WHERE str_name IN (
	'path', 'footway', 'pedestrian', 'track', 'steps', 'cycleway');

	UPDATE osm_way_classes SET kosten_auto_zeit = $3 WHERE str_name IN (
	'grade1');

	UPDATE osm_way_classes SET kosten_auto_zeit = $4 WHERE str_name IN (
	'grade2');

	UPDATE osm_way_classes SET kosten_auto_zeit = $5 WHERE str_name IN (
	'grade3');

	UPDATE osm_way_classes SET kosten_auto_zeit = $6 WHERE str_name IN (
	'grade4');

	UPDATE osm_way_classes SET kosten_auto_zeit = $7 WHERE str_name IN (
	'grade5');

	UPDATE osm_way_classes SET kosten_auto_zeit = $8 WHERE str_name IN (
	'unclassified');

	UPDATE osm_way_classes SET kosten_auto_zeit = $9 WHERE str_name IN (
	'road');
END
$$
language 'plpgsql';

SELECT kosten_auto_zeit_f(1.0, 999999.0, 1.2, 1.4, 1.6, 1.8, 2.0, 999999.0, 1.5);