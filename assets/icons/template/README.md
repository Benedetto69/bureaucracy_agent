# Generatore di icone

1. Usa un servizio come https://appicon.co/ per generare le icone (colore nero + verde, nome "Bureaucracy Agent" o simbolo "BA").
2. Salva i PNG nella cartella `assets/icons/generated/` seguendo gli stessi nomi usati nello script (`icon_mdpi.png`, `icon_hdpi.png`, ecc.).
3. Esegui `./scripts/update-icons.sh` per copiare i file nelle cartelle iOS/Android.
4. Per iOS puoi anche aprire `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` e verificare che gli slot siano aggiornati.
