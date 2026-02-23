---
category: "instructeur"
subcategory: "synchronisation"
slug: "comment-synchroniser-les-dossiers"
locale: "fr"
keywords: "synchronisation, dossiers, plateforme publique, API, récupérer, importer"
title: "Comment synchroniser les dossiers depuis la plateforme publique ?"
---

# Comment synchroniser les dossiers depuis la plateforme publique ?

La synchronisation permet de récupérer les dossiers déposés par les porteurs de projets sur [demarche.numerique.gouv.fr](https://demarche.numerique.gouv.fr/) et de les importer dans le GPP pour instruction.

## Procédure

1. Accédez à la page de suivi des dossiers de votre démarche.
2. Cliquez sur le bouton **« Synchroniser »** situé dans l'en-tête, à côté du nom de la démarche.
3. La synchronisation s'exécute et affiche un résumé : nombre de dossiers créés, mis à jour ou ignorés.

## Ce qui est synchronisé

Pour chaque dossier récupéré, le GPP importe :

- L'**identité du demandeur** : civilité, nom, prénom, adresse email.
- L'**état du dossier** sur la plateforme publique (en construction, en instruction, accepté, etc.).
- Un **lien direct** vers le dossier sur la plateforme publique.

Les dossiers importés sont automatiquement placés en état **« en instruction »** dans le GPP.

## Fréquence

La synchronisation peut être **manuelle** ou **automatique** :

- **Manuelle** : vous décidez quand récupérer les nouveaux dossiers en cliquant sur le bouton **« Synchroniser »**. Il est recommandé de synchroniser régulièrement, par exemple avant chaque session de travail ou avant un CSE.
- **Automatique** : l'administrateur peut configurer une fréquence de synchronisation (par exemple toutes les 30 minutes). Dans ce cas, les dossiers sont récupérés automatiquement sans intervention de votre part. La date de la dernière synchronisation est visible dans l'infobulle du bouton « Synchroniser ».

## Dossiers déjà synchronisés

Si un dossier a déjà été importé, la synchronisation met à jour son état sur la plateforme publique (par exemple, si un dossier est passé de « en construction » à « en instruction » côté public). Les données du dossier local ne sont pas écrasées.
