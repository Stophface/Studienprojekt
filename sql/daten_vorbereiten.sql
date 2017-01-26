-------------------------
--- Daten vorbereiten ---
-------------------------
-- osm2pgrouting erstellt in der ways Tabelle eine Spalte mit dem namen "name"
-- das ist ein in SQL reserviertes Wort und nicht so gut. 
-- Deswegen umbennen
ALTER TABLE ways RENAME COLUMN name TO str_name;
ALTER TABLE osm_way_classes RENAME COLUMN name TO str_name;

-- auf Einbahnstrassen achten
-- wenn reverse_cost < 0 sind, dann ist es nur in eine Richtung befahrbar
-- die Informationen sollten erhalten bleiben
-- ausserdem sind reverse_cost in Grad und nicht in m. 
-- Deswegen Spalte neu schreiben
ALTER TABLE ways ADD COLUMN reverse_cost_m DOUBLE PRECISION; 
UPDATE ways SET reverse_cost_m = 
CASE 
	WHEN reverse_cost < 0 THEN ST_Length(the_geom::geography) * (-1) 
	ELSE ST_Length(the_geom::geography)
END;

-- das gleiche gilt fuer length_m
-- hierfuer neue Spalte anlegen da original nicht veraendern
ALTER TABLE ways ADD COLUMN length_m_cost double precision;
UPDATE ways SET length_m_cost = 
CASE 
	WHEN cost <= 0 THEN length_m * (-1) 
	ELSE length_m
END;