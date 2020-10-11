USE `es_extended`;

INSERT INTO `addon_account` (
name,
label,
shared
) VALUES
('society_fire', 'fire', 1)
;

INSERT INTO `datastore` (
name,
label,
shared
) VALUES
('society_fire', 'fire', 1)
;

INSERT INTO `addon_inventory` (
name,
label,
shared
) VALUES
('society_fire', 'fire', 1)
;

INSERT INTO `jobs` (
name,
label
) VALUES
('fire', 'LSFD')
;

INSERT INTO `job_grades` (
job_name,
grade,
name,
label,
salary,
skin_male,
skin_female
) VALUES
('fire',0,'recruit','Rekrut',20,'{}','{}'),
('fire',1,'officer','Oficer',40,'{}','{}'),
('fire',2,'sergeant','Sierzant',60,'{}','{}'),
('fire',3,'lieutenant','Porucznik',85,'{}','{}'),
('fire',4,'boss','Komendant',100,'{}','{}')
;
