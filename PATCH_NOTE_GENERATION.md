# XHS Patch Note Generation Runbook

Ce document prepare le futur workflow pour generer un patch note a partir d'une
diff GitHub, puis publier une page web. Il ne remplace pas la relecture humaine:
la diff sert a produire une base exhaustive, ensuite on edite le resultat pour
le rendre lisible par les joueurs.

## Objectif

Generer un patch note de release, par exemple `4.0`, a partir de la diff entre
une branche de base et une branche de release.

Le workflow doit produire:

- un patch note Markdown pour review interne;
- une version web publiee sur le site;
- un resume technique exploitable pour audit;
- un footer indiquant le volume de diff analyse.

## Entrees Requises

- Version de release: exemple `4.0`.
- Branche de base: exemple `main` ou la derniere branche publiee.
- Branche de release: exemple `4.0`.
- Compare GitHub: `base...release`.
- Liste optionnelle de commits a exclure si une fusion ou un rollback pollue la
  lecture.
- Notes manuelles obligatoires:
  - message court de release;
  - highlights joueur;
  - known issues;
  - credits/contributeurs si besoin;
  - date cible de publication.

## Donnees A Extraire De La Diff

Collecter au minimum:

- commits inclus;
- fichiers modifies, ajoutes, supprimes, renommes;
- lignes ajoutees/supprimees;
- zones touchees:
  - Lua gameplay;
  - Panorama/UI;
  - localisation;
  - KV/items/abilities/units;
  - assets;
  - scripts/outillage;
  - web/backend si inclus;
- changements potentiellement invisibles joueur;
- changements potentiellement risques:
  - economie/rewards;
  - sauvegarde/profil;
  - net tables;
  - matchmaking/lobby;
  - boss/waves;
  - localisation encodee.

## Definition Du Compteur De Diff

Le footer du patch note doit afficher un compteur stable et verifiable.

Format recommande:

```text
Diff analyzed: <changed_files> files, <commits> commits, +<insertions> / -<deletions> lines.
```

Exemple:

```text
Diff analyzed: 128 files, 42 commits, +8,421 / -3,102 lines.
```

Si on veut afficher un nombre plus simple dans l'UI, utiliser `changed_files`
comme "nombre de diffs", mais garder le detail complet dans le footer ou dans
les metadonnees.

## Structure Du Patch Note

Structure cible:

```markdown
# X Hero Siege 4.0

## Highlights

## New Features

## Gameplay Changes

## Heroes

## Items

## Bosses And Waves

## UI And Quality Of Life

## Fixes

## Balance

## Technical Changes

## Known Issues

---

Diff analyzed: X files, Y commits, +A / -B lines.
```

Regles editoriales:

- ecrire pour les joueurs d'abord, pas comme un log Git;
- regrouper les micro-changements par theme;
- garder les details techniques seulement s'ils expliquent un effet joueur;
- separer les changements "Classic" et "Reborn" si la release 4.0 garde cette
  distinction;
- marquer les changements incertains comme `Needs review` plutot que d'inventer
  une intention.

## Workflow Propose

1. Verifier que la branche locale est propre.
2. Recuperer les refs GitHub a comparer.
3. Generer les statistiques:
   - commits;
   - fichiers;
   - insertions/deletions;
   - types de fichiers.
4. Lire la diff complete par lots logiques.
5. Classer chaque changement dans une categorie patch note.
6. Produire un premier Markdown brut.
7. Ajouter les notes manuelles de release.
8. Faire une passe de nettoyage joueur:
   - titres courts;
   - doublons retires;
   - changements internes deplaces en `Technical Changes`;
   - known issues ajoutes.
9. Exporter les metadonnees JSON pour la page web.
10. Generer ou mettre a jour la page web.
11. Verifier visuellement la page.
12. Publier uniquement apres validation humaine.

## Web Publication

Les informations d'acces backend/frontend ne doivent pas etre copiees dans ce
repo public. Au moment de publier, lire les notes privees dans `../xhs_ai/`:

- `../xhs_ai/x_hero_siege_notes/backend_access.md`
- `../xhs_ai/scripts/supporter_pass_liveops/README.md` si une integration
  backend Node `/xhs/*` est necessaire

Frontend cible documente dans les notes privees:

- application Vue du site;
- build via `npm run build` dans le dossier frontend;
- verification du `dist` apres build.

### Format actuel du site

Reference observee: `https://mods.frostrose-studio.com/patches/xhs/3.51d`.

Le site actuel est une application Vue. Les patch notes XHS sont embarques dans
le bundle frontend sous forme de donnees statiques, avec une route par version:

```text
/patches/xhs/<version>
```

Champs detectes pour une entree de patch:

```json
{
  "version": "3.51d",
  "title": "Stability patch",
  "status": "current",
  "statusLabel": "Current",
  "route": "/patches/xhs/3.51d",
  "summary": "Bug fixes after the Dota 7.33 update and general stability improvements.",
  "details": [],
  "sections": [],
  "impact": []
}
```

Les entrees archivees utilisent surtout:

```json
{
  "details": [
    {
      "title": "Player identity",
      "items": [
        "Prepared profile badge slots for XHS supporter tiers."
      ]
    }
  ]
}
```

Pour la 4.0, garder cette compatibilite:

- `version`: `4.0`;
- `title`: titre court, lisible dans les cartes et l'archive;
- `status`: `current` au moment de publication, puis `archive` plus tard;
- `statusLabel`: `Current` ou `Archive`;
- `route`: `/patches/xhs/4.0`;
- `summary`: une phrase de contexte joueur;
- `details`: sections principales affichees sur la page;
- `sections` et `impact`: a remplir seulement si le composant frontend les
  affiche ou si on etend le composant.

Le compteur de diff peut etre ajoute sans changer l'API de donnees en creant
une section `details` finale:

```json
{
  "title": "Release audit",
  "items": [
    "Diff analyzed: 128 files, 42 commits, +8,421 / -3,102 lines."
  ]
}
```

Si on modifie le composant Vue, preferer un vrai footer visuel base sur
`meta.diffStats`, mais garder une fallback textuelle dans `details` pour les
anciennes pages.

Suggestion d'integration:

- stocker les patch notes comme donnees versionnees cote frontend si le contenu
  est statique;
- utiliser une route backend seulement si on veut une liste dynamique, des vues,
  un statut de publication, ou un outil admin;
- exposer les metadonnees dans la page:
  - version;
  - date;
  - branche de base;
  - branche de release;
  - compare URL;
  - changed files;
  - commits;
  - insertions/deletions.

## Fichiers De Sortie Recommandes

Les noms exacts pourront etre ajustes plus tard.

```text
patch_notes/
  4.0.md
  4.0.meta.json
```

`4.0.md` contient le texte edite.

`4.0.meta.json` contient les chiffres et la provenance:

```json
{
  "version": "4.0",
  "baseRef": "main",
  "releaseRef": "4.0",
  "compareUrl": "https://github.com/<owner>/<repo>/compare/main...4.0",
  "commitCount": 0,
  "changedFiles": 0,
  "insertions": 0,
  "deletions": 0,
  "generatedAt": "YYYY-MM-DDTHH:mm:ssZ"
}
```

## Suggestions A Ajouter Au Workflow

- Ajouter une allowlist/denylist de chemins pour eviter que les fichiers generes,
  temporaires ou vendores gonflent le patch note.
- Marquer les changements de localisation separement: ils peuvent etre tres
  nombreux mais peu interessants pour les joueurs.
- Detecter les fichiers critiques et forcer une section `Risk Review`.
- Garder un bloc `Manual Highlights` au-dessus de la generation automatique,
  pour imposer le message de release.
- Conserver une trace `source map` entre chaque bullet du patch note et les
  commits/fichiers qui l'ont inspire.
- Generer une version courte pour Steam/Discord et une version longue pour le
  site.
- Ajouter une passe anti-hallucination: chaque bullet important doit pointer
  vers au moins un commit ou fichier modifie.
- Prevoir un mode `draft` et un mode `publish`.
- Verifier les captures/images si la page web contient des visuels.
- Garder les secrets, mots de passe, IP privees et notes d'acces dans
  `../xhs_ai/`, jamais dans le repo public.

## Checklist Avant Generation 4.0

- [ ] Confirmer `baseRef`.
- [ ] Confirmer `releaseRef`.
- [ ] Confirmer le format exact du footer.
- [ ] Confirmer si le patch note doit etre bilingue ou anglais seulement.
- [ ] Confirmer le chemin final des fichiers `patch_notes/`.
- [ ] Lire les notes privees `../xhs_ai/` pour publication web.
- [ ] Generer le Markdown draft.
- [ ] Relire et corriger les sections joueur.
- [ ] Generer/mettre a jour la page web.
- [ ] Verifier le rendu desktop/mobile.
- [ ] Publier.
