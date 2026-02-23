---
category: "administrateur"
subcategory: "configuration"
slug: "configurer-synchronisation-automatique"
locale: "fr"
keywords: "synchronisation automatique, dossiers, périodicité, fréquence, API, plateforme publique"
title: "Comment configurer la synchronisation automatique des dossiers ?"
---

# Comment configurer la synchronisation automatique des dossiers ?

La synchronisation automatique permet de récupérer régulièrement les dossiers depuis la plateforme publique sans intervention manuelle des instructeurs. La fréquence est définie par l'administrateur pour chaque démarche.

## Prérequis

- La démarche doit être **liée à une démarche publique** (bloc « Liaison avec la démarche publique » configuré).
- Un **token API** valide doit être renseigné dans la configuration de l'instance GPP.

## Accès

1. Accédez à la page de gestion de votre démarche.
2. Dans la section **« Autres paramètres »**, cliquez sur le bouton **« Synchronisation auto. »**.

## Configuration de la fréquence

Cochez **« Activer la synchronisation automatique »** pour afficher le champ de fréquence. Saisissez un nombre et choisissez l'unité : **minutes**, **heures** ou **jours**. Par exemple, `30 minutes` ou `2 heures`.

Cliquez sur **« Enregistrer »** pour appliquer la configuration.

## Comportement

- Une fois activée, la première synchronisation s'effectue après l'intervalle configuré.
- Chaque synchronisation déclenche la suivante automatiquement. Si l'application redémarre, les synchronisations en attente sont reprises au démarrage.
- La date et l'heure de la dernière synchronisation sont visibles dans l'infobulle du bouton **« Synchroniser »** sur la page de suivi des dossiers.

## Désactivation

Pour désactiver la synchronisation automatique, revenez sur la page de configuration et sélectionnez **« Désactivée »**, puis enregistrez.
