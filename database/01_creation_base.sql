CREATE DATABASE IF NOT EXISTS platinium_auto
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE platinium_auto;

CREATE TABLE utilisateurs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    telephone VARCHAR(30) NULL,
    role ENUM('client', 'employe', 'proprietaire')
        NOT NULL DEFAULT 'client',
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE vehicules (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    categorie_id INT UNSIGNED NOT NULL,
    marque VARCHAR(100) NOT NULL,
    modele VARCHAR(100) NOT NULL,
    immatriculation VARCHAR(30) NOT NULL UNIQUE,
    transmission ENUM('manuelle', 'automatique') NOT NULL,
    carburant ENUM('essence', 'diesel', 'hybride', 'electrique') NOT NULL,
    nombre_places TINYINT UNSIGNED NOT NULL,
    kilometrage INT UNSIGNED NOT NULL DEFAULT 0,
    prix_24h DECIMAL(10, 2) NOT NULL,
    prix_12h DECIMAL(10, 2) NOT NULL,
    photo VARCHAR(255) NULL,
    description TEXT NULL,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_vehicules_categories
        FOREIGN KEY (categorie_id)
        REFERENCES categories(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_vehicules_places
        CHECK (nombre_places BETWEEN 1 AND 9),

    CONSTRAINT chk_vehicules_prix_24h
        CHECK (prix_24h > 0),

    CONSTRAINT chk_vehicules_prix_12h
        CHECK (prix_12h > 0 AND prix_12h <= prix_24h)
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE reservations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id INT UNSIGNED NOT NULL,
    vehicule_id INT UNSIGNED NOT NULL,

    date_debut DATETIME NOT NULL,
    date_fin DATETIME NOT NULL,

    statut ENUM(
        'en_attente',
        'acceptee',
        'confirmee',
        'en_cours',
        'terminee',
        'refusee',
        'annulee'
    ) NOT NULL DEFAULT 'en_attente',

    prix_24h_applique DECIMAL(10, 2) NOT NULL,
    prix_12h_applique DECIMAL(10, 2) NOT NULL,
    duree_facturee_heures INT UNSIGNED NOT NULL,
    montant_location DECIMAL(12, 2) NOT NULL,

    motif_refus TEXT NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_reservations_clients
        FOREIGN KEY (client_id)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservations_vehicules
        FOREIGN KEY (vehicule_id)
        REFERENCES vehicules(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_reservations_duree_minimale
        CHECK (date_fin >= DATE_ADD(date_debut, INTERVAL 24 HOUR)),

    CONSTRAINT chk_reservations_duree_facturee
        CHECK (
            duree_facturee_heures >= 24
            AND MOD(duree_facturee_heures, 12) = 0
        ),

    CONSTRAINT chk_reservations_tarifs
        CHECK (
            prix_24h_applique > 0
            AND prix_12h_applique > 0
            AND prix_12h_applique <= prix_24h_applique
        ),

    CONSTRAINT chk_reservations_montant
        CHECK (montant_location > 0),

    INDEX idx_reservations_disponibilite (
        vehicule_id,
        statut,
        date_debut,
        date_fin
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE indisponibilites (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicule_id INT UNSIGNED NOT NULL,
    reservation_id INT UNSIGNED NULL,
    cree_par INT UNSIGNED NOT NULL,

    motif ENUM(
        'nettoyage_revision',
        'entretien',
        'reparation',
        'autre'
    ) NOT NULL,

    date_debut DATETIME NOT NULL,
    date_fin_prevue DATETIME NOT NULL,
    description TEXT NULL,

    date_validation_fin DATETIME NULL,
    valide_par INT UNSIGNED NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_indisponibilites_vehicules
        FOREIGN KEY (vehicule_id)
        REFERENCES vehicules(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_indisponibilites_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_indisponibilites_createurs
        FOREIGN KEY (cree_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_indisponibilites_validateurs
        FOREIGN KEY (valide_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_indisponibilites_dates
        CHECK (date_fin_prevue > date_debut),

    CONSTRAINT chk_indisponibilites_nettoyage
        CHECK (
            motif <> 'nettoyage_revision'
            OR date_fin_prevue >= DATE_ADD(
                date_debut, INTERVAL 24 HOUR
            )
        ),

    CONSTRAINT chk_indisponibilites_validation
        CHECK (
            (
                date_validation_fin IS NULL
                AND valide_par IS NULL
            )
            OR
            (
                date_validation_fin IS NOT NULL
                AND valide_par IS NOT NULL
                AND date_validation_fin >= date_debut
            )
        ),

    INDEX idx_indisponibilites_periode (
        vehicule_id,
        date_debut,
        date_fin_prevue
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE documents_client (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL,

    type_document ENUM(
        'permis',
        'identite',
        'autre'
    ) NOT NULL,

    chemin_fichier VARCHAR(255) NOT NULL,
    nom_original VARCHAR(255) NOT NULL,
    type_mime VARCHAR(100) NOT NULL,
    taille_octets INT UNSIGNED NOT NULL,

    statut ENUM(
        'en_attente',
        'valide',
        'refuse'
    ) NOT NULL DEFAULT 'en_attente',

    motif_refus TEXT NULL,
    verifie_par INT UNSIGNED NULL,
    date_verification DATETIME NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_documents_client_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_documents_client_verificateurs
        FOREIGN KEY (verifie_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_documents_client_taille
        CHECK (taille_octets > 0),

    CONSTRAINT chk_documents_client_verification
        CHECK (
            (
                statut = 'en_attente'
                AND verifie_par IS NULL
                AND date_verification IS NULL
            )
            OR
            (
                statut IN ('valide', 'refuse')
                AND verifie_par IS NOT NULL
                AND date_verification IS NOT NULL
            )
        ),

    CONSTRAINT chk_documents_client_refus
        CHECK (
            statut <> 'refuse'
            OR (
                motif_refus IS NOT NULL
                AND CHAR_LENGTH(TRIM(motif_refus)) > 0
            )
        ),

    INDEX idx_documents_client_reservation (
        reservation_id,
        type_document,
        statut
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE paiements (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL,

    reference_interne VARCHAR(100) NOT NULL UNIQUE,
    prestataire VARCHAR(50) NOT NULL,
    reference_prestataire VARCHAR(191) NULL,

    montant DECIMAL(12, 2) NOT NULL,
    devise CHAR(3) NOT NULL DEFAULT 'MAD',

    statut ENUM(
        'en_attente',
        'reussi',
        'echoue',
        'annule',
        'expire'
    ) NOT NULL DEFAULT 'en_attente',

    mode_test BOOLEAN NOT NULL DEFAULT TRUE,
    date_paiement DATETIME NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_paiements_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_paiements_reference_prestataire
        UNIQUE (prestataire, reference_prestataire),

    CONSTRAINT chk_paiements_montant
        CHECK (montant > 0),

    CONSTRAINT chk_paiements_date
        CHECK (
            (
                statut = 'reussi'
                AND date_paiement IS NOT NULL
            )
            OR
            (
                statut <> 'reussi'
                AND date_paiement IS NULL
            )
        ),

    INDEX idx_paiements_reservation (
        reservation_id,
        statut
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE demandes_annulation (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL,
    demande_par INT UNSIGNED NOT NULL,

    motif_demande TEXT NOT NULL,

    statut ENUM(
        'en_attente',
        'acceptee',
        'refusee'
    ) NOT NULL DEFAULT 'en_attente',

    date_demande DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    traite_par INT UNSIGNED NULL,
    date_traitement DATETIME NULL,
    commentaire_traitement TEXT NULL,

    frais_annulation DECIMAL(12, 2) NULL,
    montant_a_rembourser DECIMAL(12, 2) NULL,

    CONSTRAINT fk_annulations_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_annulations_demandeurs
        FOREIGN KEY (demande_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_annulations_employes
        FOREIGN KEY (traite_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_annulations_motif
        CHECK (CHAR_LENGTH(TRIM(motif_demande)) > 0),

    CONSTRAINT chk_annulations_traitement
        CHECK (
            (
                statut = 'en_attente'
                AND traite_par IS NULL
                AND date_traitement IS NULL
            )
            OR
            (
                statut IN ('acceptee', 'refusee')
                AND traite_par IS NOT NULL
                AND date_traitement IS NOT NULL
                AND date_traitement >= date_demande
            )
        ),

    CONSTRAINT chk_annulations_montants
        CHECK (
            (frais_annulation IS NULL OR frais_annulation >= 0)
            AND
            (montant_a_rembourser IS NULL OR montant_a_rembourser >= 0)
        ),

    CONSTRAINT chk_annulations_acceptation
        CHECK (
            statut <> 'acceptee'
            OR (
                frais_annulation IS NOT NULL
                AND montant_a_rembourser IS NOT NULL
            )
        ),

    INDEX idx_annulations_reservation (
        reservation_id,
        statut
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE remboursements (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    paiement_id INT UNSIGNED NOT NULL,
    demande_annulation_id INT UNSIGNED NOT NULL,
    demande_par INT UNSIGNED NOT NULL,

    reference_interne VARCHAR(100) NOT NULL UNIQUE,
    reference_prestataire VARCHAR(191) NULL,

    montant DECIMAL(12, 2) NOT NULL,

    statut ENUM(
        'en_attente',
        'reussi',
        'echoue',
        'annule'
    ) NOT NULL DEFAULT 'en_attente',

    motif_echec TEXT NULL,
    date_remboursement DATETIME NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_remboursements_paiements
        FOREIGN KEY (paiement_id)
        REFERENCES paiements(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_remboursements_annulations
        FOREIGN KEY (demande_annulation_id)
        REFERENCES demandes_annulation(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_remboursements_demandeurs
        FOREIGN KEY (demande_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_remboursements_reference
        UNIQUE (paiement_id, reference_prestataire),

    CONSTRAINT chk_remboursements_montant
        CHECK (montant > 0),

    CONSTRAINT chk_remboursements_date
        CHECK (
            (
                statut = 'reussi'
                AND date_remboursement IS NOT NULL
            )
            OR
            (
                statut <> 'reussi'
                AND date_remboursement IS NULL
            )
        ),

    INDEX idx_remboursements_annulation (
        demande_annulation_id,
        statut
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE blocages_paiement (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL,
    paiement_id INT UNSIGNED NOT NULL UNIQUE,

    statut ENUM(
        'actif',
        'converti',
        'expire',
        'libere'
    ) NOT NULL DEFAULT 'actif',

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_expiration DATETIME NOT NULL,
    date_cloture DATETIME NULL,

    CONSTRAINT fk_blocages_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_blocages_paiements
        FOREIGN KEY (paiement_id)
        REFERENCES paiements(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_blocages_expiration
        CHECK (
            date_expiration = DATE_ADD(
                date_creation, INTERVAL 15 MINUTE
            )
        ),

    CONSTRAINT chk_blocages_cloture
        CHECK (
            (
                statut = 'actif'
                AND date_cloture IS NULL
            )
            OR
            (
                statut <> 'actif'
                AND date_cloture IS NOT NULL
                AND date_cloture >= date_creation
            )
        ),

    INDEX idx_blocages_reservation (
        reservation_id,
        statut,
        date_expiration
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE etats_lieux (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL,
    realise_par INT UNSIGNED NOT NULL,

    type_etat ENUM('depart', 'retour') NOT NULL,
    date_constat DATETIME NOT NULL,
    kilometrage INT UNSIGNED NOT NULL,
    carburant_pourcentage TINYINT UNSIGNED NOT NULL,
    observations TEXT NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_etats_lieux_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_etats_lieux_employes
        FOREIGN KEY (realise_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_etats_lieux_reservation_type
        UNIQUE (reservation_id, type_etat),

    CONSTRAINT chk_etats_lieux_carburant
        CHECK (carburant_pourcentage BETWEEN 0 AND 100)
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE frais_retour (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL UNIQUE,
    calcule_par INT UNSIGNED NOT NULL,

    heures_retard_facturees INT UNSIGNED NOT NULL DEFAULT 0,
    tarif_journalier_applique DECIMAL(10, 2) NOT NULL,
    taux_retard_pourcentage DECIMAL(5, 2) NOT NULL DEFAULT 10.00,

    litres_manquants DECIMAL(8, 2) NOT NULL DEFAULT 0,
    prix_litre_applique DECIMAL(8, 2) NOT NULL DEFAULT 0,
    frais_remise_niveau DECIMAL(10, 2) NOT NULL DEFAULT 0,

    observations TEXT NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_frais_retour_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_frais_retour_employes
        FOREIGN KEY (calcule_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_frais_retour_tarif
        CHECK (tarif_journalier_applique > 0),

    CONSTRAINT chk_frais_retour_taux
        CHECK (
            taux_retard_pourcentage > 0
            AND taux_retard_pourcentage <= 100
        ),

    CONSTRAINT chk_frais_retour_carburant
        CHECK (
            (
                litres_manquants = 0
                AND prix_litre_applique = 0
                AND frais_remise_niveau = 0
            )
            OR
            (
                litres_manquants > 0
                AND prix_litre_applique > 0
                AND frais_remise_niveau = 100.00
            )
        )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE documents_location (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL,
    genere_par INT UNSIGNED NOT NULL,

    type_document ENUM(
        'contrat',
        'facture',
        'recapitulatif'
    ) NOT NULL,

    reference_document VARCHAR(100) NOT NULL UNIQUE,
    chemin_fichier VARCHAR(255) NOT NULL,
    nom_fichier VARCHAR(255) NOT NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_documents_location_reservations
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_documents_location_createurs
        FOREIGN KEY (genere_par)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_documents_location_reference
        CHECK (
            CHAR_LENGTH(TRIM(reference_document)) > 0
        ),

    CONSTRAINT chk_documents_location_chemin
        CHECK (
            CHAR_LENGTH(TRIM(chemin_fichier)) > 0
        ),

    INDEX idx_documents_location_reservation (
        reservation_id,
        type_document
    )
) ENGINE = InnoDB;

USE platinium_auto;

CREATE TABLE historique_actions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NULL,

    action VARCHAR(100) NOT NULL,
    entite VARCHAR(50) NOT NULL,
    entite_id INT UNSIGNED NOT NULL,
    description TEXT NULL,

    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_historique_utilisateurs
        FOREIGN KEY (utilisateur_id)
        REFERENCES utilisateurs(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_historique_action
        CHECK (CHAR_LENGTH(TRIM(action)) > 0),

    CONSTRAINT chk_historique_entite
        CHECK (CHAR_LENGTH(TRIM(entite)) > 0),

    CONSTRAINT chk_historique_entite_id
        CHECK (entite_id > 0),

    INDEX idx_historique_entite (
        entite,
        entite_id,
        date_creation
    ),

    INDEX idx_historique_utilisateur (
        utilisateur_id,
        date_creation
    )
) ENGINE = InnoDB;