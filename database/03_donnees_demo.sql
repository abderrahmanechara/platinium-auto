USE platinium_auto;

INSERT INTO vehicules (
    categorie_id,
    marque,
    modele,
    immatriculation,
    transmission,
    carburant,
    nombre_places,
    kilometrage,
    prix_24h,
    prix_12h,
    description
)
SELECT
    id,
    'Mercedes-Benz',
    'Classe S',
    'DEMO-001',
    'automatique',
    'essence',
    5,
    24500,
    1200.00,
    700.00,
    'Berline de luxe — véhicule fictif de démonstration.'
FROM categories
WHERE nom = 'Berline';