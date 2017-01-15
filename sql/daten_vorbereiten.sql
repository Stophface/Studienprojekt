-- Spalten umbennen
ALTER TABLE ways RENAME COLUMN name TO str_name;
ALTER TABLE osm_way_classes RENAME COLUMN name TO str_name;

-- Kostenspalten hinzufuegen
-- Berechnung der Kosten folgt spaeter
ALTER TABLE osm_way_classes ADD COLUMN kosten_fuss FLOAT;
UPDATE osm_way_classes SET kosten_fuss = 1.0;
ALTER TABLE osm_way_classes ADD COLUMN kosten_auto_weg FLOAT;
UPDATE osm_way_classes SET kosten_auto_weg = 1.0;
ALTER TABLE osm_way_classes ADD COLUMN kosten_auto_zeit FLOAT;
UPDATE osm_way_classes SET kosten_auto_zeit = 1.0;