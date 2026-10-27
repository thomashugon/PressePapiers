# PressePapiers

Une petite app pour macOS qui garde l'historique de tout ce que vous copiez, pour pouvoir recoller n'importe lequel de vos derniers copier-coller.

## Utilisation

- Copiez du texte comme d'habitude (⌘C). Chaque copie est ajoutée à l'historique (50 éléments au maximum, plus les éléments épinglés).
- Appuyez sur **⌘⇧V** n'importe où : une fenêtre s'ouvre près de la souris avec vos copies.
  - Tapez quelques lettres pour **rechercher**.
  - **↑ ↓** pour choisir, **↩** pour coller. Un clic fait la même chose.
  - **⌘1 à ⌘9** collent directement l'élément numéroté.
  - **Échap** ferme la fenêtre.
  - **Clic droit** sur un élément pour l'**épingler** (il reste toujours en haut et n'est jamais effacé) ou le supprimer.
- L'icône 📋 dans la barre des menus affiche aussi les 15 dernières copies, et permet d'effacer l'historique, de lancer l'app au démarrage ou de la quitter.

Les copies venant d'un gestionnaire de mots de passe (1Password, Bitwarden, etc.) sont ignorées. L'historique est enregistré dans `~/Library/Application Support/PressePapiers/historique.json`.

## Installation (une seule fois)

Il faut macOS 14 (Sonoma) ou plus récent.

1. **Installer les outils de compilation d'Apple.** Ouvrez l'app Terminal et tapez :
   ```
   xcode-select --install
   ```
   Une fenêtre s'ouvre, cliquez sur « Installer » (quelques minutes). Si Xcode est déjà installé, passez cette étape.

2. **Compiler l'app.** Dans le Terminal, placez-vous dans le dossier `PressePapiers` (tapez `cd ` puis glissez le dossier dans la fenêtre du Terminal, puis Entrée), et lancez :
   ```
   ./build-app.sh
   ```

3. **Installer et ouvrir :**
   ```
   cp -R build/PressePapiers.app /Applications/
   open /Applications/PressePapiers.app
   ```
   L'icône 📋 apparaît dans la barre des menus, en haut à droite.

4. **Autoriser le collage automatique.** Pour que l'app puisse coller toute seule dans l'app ouverte, macOS demande l'autorisation « Accessibilité ». Au premier collage, une fenêtre propose d'ouvrir les Réglages : allez dans **Réglages Système › Confidentialité et sécurité › Accessibilité** et activez **PressePapiers**.
   Sans cette autorisation, l'app fonctionne quand même : l'élément choisi est remis dans le presse-papiers, il suffit alors de faire ⌘V.

5. *(Facultatif)* Dans le menu 📋, cochez **Lancer au démarrage**.

## Bon à savoir

- Si vous recompilez l'app, macOS peut considérer que c'est une nouvelle app : retirez PressePapiers de la liste Accessibilité (bouton −) puis réactivez-le.
- Pour changer le raccourci ⌘⇧V, modifiez la ligne `HotKey(keyCode: …, modifiers: …)` dans `Sources/PressePapiers/PressePapiersApp.swift` (par exemple `UInt32(cmdKey | optionKey)` pour ⌘⌥V), puis relancez `./build-app.sh`.
- Pour ouvrir le projet dans Xcode : `open Package.swift`.
