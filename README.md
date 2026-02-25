# Portails — Gestionnaire des Processus Projets (GIP CAD)

## Vue d'ensemble

Le Gestionnaire des Processus Projets (GPP) est un fork du code open source de [demarches-simplifiees.fr](https://github.com/demarches-simplifiees/demarches-simplifiees.fr), transformé pour répondre aux besoins du GIP CAD. Le code d'origine — conçu comme une plateforme généraliste de dépôt et d'instruction de démarches administratives — est remanié pour servir un objectif spécifique : l'instruction des dossiers de candidature déposés sur la plateforme publique nationale.

Le GPP ne gère pas le dépôt des dossiers par les usagers. Il se connecte à [demarche.numerique.gouv.fr](https://demarche.numerique.gouv.fr/) via son API GraphQL pour récupérer les dossiers déposés, puis offre aux instructeurs du GIP CAD un environnement d'instruction dédié avec des outils spécifiques : checklist de vérification, notes et pièces jointes par champ, et gestion du calendrier CSE.

---

## Installation

### Dépendances techniques

- **PostgreSQL** (version >= 15)
- **Redis** (pour Sidekiq, le traitement des jobs asynchrones)
- **rbenv** : voir https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts
- **Bun** : voir https://bun.sh/docs/installation
- **imagemagick** et **gsfonts** pour générer les filigranes sur les titres d'identité et les miniatures d'images

> [!WARNING]
> Pensez à restreindre la policy d'ImageMagick pour bloquer l'exploitation d'images malveillantes.
> La configuration par défaut est généralement insuffisante pour des images provenant du web.
> Par exemple sous debian/ubuntu dans `/etc/ImageMagick-6/policy.xml` :

```xml
<!-- en plus de la policy par défaut, ajoutez à la fin du fichier -->
<policymap>
    <policy domain="coder" rights="none" pattern="*"/>
    <policy domain="coder" rights="read | write" pattern="{JPG,JPEG,PNG,JSON}"/>
    <policy domain="module" rights="none" pattern="{MSL,MVG,PS,SVG,URL,XPS}"/>
</policymap>
```

Pour les tests : **Chrome** et **chromedriver** (voir https://developer.chrome.com/blog/chrome-for-testing).

### Création des rôles de la base de données

Les informations nécessaires à l'initialisation de la base doivent être pré-configurées à la main :

    su - postgres
    psql
    > create user gpp_development with password 'gpp_development' superuser;
    > create user gpp_test with password 'gpp_test' superuser;
    > \q

Sous Ubuntu, certains packages doivent être installés au préalable :

    sudo apt-get install libcurl3 libcurl3-gnutls libcurl4-openssl-dev libcurl4-gnutls-dev zlib1g-dev

### Initialisation de l'environnement

Exécutez la commande suivante pour créer la base de données, installer les dépendances et préparer l'environnement :

    bin/setup

### Configuration

Le GPP se configure via le fichier `.env` à la racine du projet (voir `config/env.example` pour la liste complète). Les variables spécifiques au GPP :

| Variable | Description |
|----------|-------------|
| `PUBLIC_DS_API_URL` | URL de l'instance publique (ex : `https://demarche.numerique.gouv.fr`) |
| `PUBLIC_DS_API_TOKEN` | Token API généré sur l'instance publique, pour authentifier les appels GraphQL |
| `APPLICATION_NAME` | Nom affiché dans l'en-tête (par défaut : `Gestionnaire des Processus Projets`) |

---

## Lancement de l'application

```bash
bin/dev
```

L'application est accessible à l'adresse http://localhost:3000 avec en parallèle un worker pour les jobs et le bundler Vite.

Pour lancer uniquement le serveur Rails (sans worker ni Vite) :

```bash
bin/rails server
```

Le port peut être modifié avec l'option `-p` :

```bash
bin/rails server -p 3001
```

### Utilisateurs de test

En local, un utilisateur de test est créé automatiquement par `bin/setup`, avec les identifiants `test@exemple.fr` / `this is a very complicated password !` (voir [db/seeds.rb](db/seeds.rb)).

### Emails envoyés en local

Ouvrez la page http://localhost:3000/letter_opener.

### Mise à jour

Pour mettre à jour l'environnement de développement, installer les nouvelles dépendances et exécuter les migrations :

    bin/update

---

## Prérequis côté plateforme publique

L'instance publique demarche.numerique.gouv.fr est un service existant, administré indépendamment. Côté public, il suffit de :

1. **Disposer d'un compte administrateur** sur demarche.numerique.gouv.fr
2. **Créer et publier une démarche** avec le formulaire destiné aux usagers
3. **Générer un token API** (dans les paramètres de la démarche, rubrique « Token API ») — ce token sera utilisé par le GPP pour interroger l'API GraphQL

---

## Workflow complet

### 1. Créer une démarche d'instruction sur le GPP

Sur le GPP, un administrateur crée une démarche qui servira de support à l'instruction :

1. Se connecter en tant qu'administrateur
2. Créer une nouvelle démarche
3. Configurer les champs du formulaire comme des **critères de vérification** — typiquement des champs Oui/Non correspondant aux points de contrôle que l'instructeur devra valider (ex : « Identité du demandeur vérifiée », « Données demandées existent dans l'EDS »)
4. Publier la démarche

### 2. Lier la démarche GPP à la démarche publique

Sur la page de gestion de la démarche (`/admin/procedures/N`), un bloc « Liaison avec la démarche publique » apparaît en haut de la page :

1. Saisir le **numéro de la démarche publique** correspondante sur demarche.numerique.gouv.fr
2. Cliquer « Lier »

Cela crée une association (`ProcedureMirror`) entre la démarche locale et la démarche publique. Un lien « (voir) » permet de naviguer directement vers la démarche sur l'instance publique. La liaison peut être supprimée à tout moment via le bouton « Délier ».

### 3. Les usagers déposent leurs dossiers sur la plateforme publique

Les demandeurs accèdent à la démarche sur demarche.numerique.gouv.fr, remplissent le formulaire et déposent leur dossier. Cette étape est entièrement gérée par la plateforme publique — le GPP n'intervient pas.

### 4. Synchroniser les dossiers

La synchronisation peut être déclenchée de deux manières :

- **Manuellement** : sur la page de suivi des dossiers (`/procedures/N/tous`), un bouton « Synchroniser » apparaît dans l'en-tête. Un bouton équivalent est aussi disponible sur la page de configuration de synchronisation de la démarche (Administration).
- **Automatiquement** : sur la page de gestion de la démarche, le bouton « Synchronisation auto. » permet de configurer une fréquence de synchronisation périodique (en minutes, heures ou jours).

La synchronisation utilise l'API GraphQL (`PublicDossierSyncService`) :

- **Nouveaux dossiers** : un dossier local est créé en état « en instruction » avec les informations du demandeur (civilité, nom, prénom, email). Un `LinkedDossier` conserve le lien vers le dossier public (numéro, URL, état).
- **Dossiers existants** : l'état du dossier public est mis à jour si nécessaire.

### 5. Instruire un dossier

L'instructeur ouvre un dossier synchronisé. La page du dossier présente plusieurs blocs :

#### Bloc « Dossier lié »
- Lien direct vers le dossier sur demarche.numerique.gouv.fr (ouvre dans un nouvel onglet)
- Badge d'état du dossier public (en construction, en instruction, accepté, etc.)
- Identité du demandeur : civilité, prénom, nom, adresse email

#### Bloc « Vérifications du dossier » (checklist)
Les champs Oui/Non définis dans la démarche GPP sont présentés comme une checklist :

- L'instructeur coche Oui ou Non pour chaque critère de contrôle
- Sous chaque champ, il peut ajouter une **note** (texte libre, sauvegarde automatique) pour justifier sa décision
- Il peut joindre des **pièces justificatives** à chaque note (fichiers téléversés, supprimables individuellement)

#### Contrainte de validation
Le bouton « Accepter » dans le menu d'instruction est **désactivé** tant que tous les champs Oui/Non ne sont pas cochés « Oui ». Un tooltip explique cette contrainte. Les actions « Classer sans suite » et « Refuser » restent disponibles à tout moment.

#### Vue lecture seule
Une fois le dossier terminé (accepté, refusé ou classé sans suite), les vérifications, notes et pièces jointes sont affichées en lecture seule dans le récapitulatif.

---

## Tableau de suivi des dossiers

Le tableau des dossiers affiche par défaut les colonnes suivantes :

| Colonne | Description |
|---------|-------------|
| N° dossier | Numéro du dossier local |
| Demandeur | Email du demandeur |
| Date de dépôt | Date à laquelle le demandeur a déposé le dossier sur la plateforme publique |
| N° dossier lié | Numéro du dossier public (lien cliquable vers demarche.numerique.gouv.fr) |
| État du dossier lié | État actuel du dossier sur la plateforme publique |

Le tableau est trié par date de dépôt (du plus ancien au plus récent) par défaut.

---

## Module Calendrier CSE

Les dossiers déposés sont examinés lors de Comités Sociaux et Économiques (CSE) mensuels. Un dossier doit être déposé **au moins 2 semaines avant la date du CSE** (T0 − 2 semaines) pour être étudié lors de cette session.

### Configuration (administrateur)

Sur la page de gestion de la démarche, le bouton « Calendrier CSE » (bloc « Autres paramètres ») mène à une page de configuration :

- Un **calendrier interactif** permet de sélectionner/désélectionner des dates en cliquant dessus
- La liste des dates sélectionnées s'affiche à droite avec la date limite de dépôt calculée automatiquement (T0 − 2 semaines)
- Bouton « Enregistrer » pour sauvegarder, « Annuler et revenir à l'écran de gestion » pour abandonner (avec confirmation)

### Affichage dans le tableau des dossiers (instructeur)

Lorsque le tableau est trié par date de dépôt, un **séparateur visuel** apparaît :

- Une barre bleue indique la date du prochain CSE et la date limite de dépôt correspondante
- Les dossiers déposés **après** la date limite sont **grisés** (opacité réduite) — ils ne seront pas étudiés lors du prochain CSE
- Les dossiers déposés **avant** la date limite apparaissent normalement — ils sont éligibles

Le séparateur n'apparaît que lorsque le tableau est trié par date de dépôt.

---

## Tests

Les tests ont besoin de leur propre base de données et certains d'entre eux utilisent Selenium pour s'exécuter dans un navigateur.

- Lancer tous les tests : `bin/rspec`
- Lancer un test en particulier : `bin/rspec file_path/file_name_spec.rb:line_number`
- Relancer uniquement les tests échoués : `bin/rspec --only-failures`
- Tests système avec navigateur visible : `NO_HEADLESS=1 bin/rspec spec/system`
- Afficher les logs JS de la console : `JS_LOG=debug,log,error bin/rspec spec/system`

### Linting

Faire tourner tous les linters : `bin/rake lint`

---

## Modèles de données ajoutés

| Modèle | Description |
|--------|-------------|
| `ProcedureMirror` | Associe une démarche GPP à une démarche publique (URL + numéro) |
| `LinkedDossier` | Lie un dossier local à un dossier public (numéro, URL, état, identité du demandeur) |
| `ChampNote` | Note de l'instructeur sur un champ de vérification (texte + pièces jointes) |
| `CseDate` | Date d'un CSE configurée pour une démarche |
