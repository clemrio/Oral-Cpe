#!/bin/bash

# Vérifiez si pandoc est installé
if ! command -v pandoc &> /dev/null
then
    echo "pandoc n'est pas installé. Vous pouvez l'installer via Homebrew : brew install pandoc"
    exit
fi

# Répertoire contenant les fichiers .docx
DIRECTORY=$1

# Vérifiez si le répertoire est spécifié
if [ -z "$DIRECTORY" ]; then
    echo "Veuillez spécifier le répertoire contenant les fichiers .docx."
    exit 1
fi

# Vérifiez si le répertoire existe
if [ ! -d "$DIRECTORY" ]; then
    echo "Le répertoire spécifié n'existe pas."
    exit 1
fi

# Fichier de sortie
OUTPUT_FILE="Readme.md"
TEMP_FILE="temp.md"

# Supprimez le fichier de sortie s'il existe déjà
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# En-tête du fichier Readme.md
echo "# Table of Contents" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Convertissez et fusionnez tous les fichiers .docx en Readme.md
for FILE in "$DIRECTORY"/*.docx; do
    if [ -f "$FILE" ]; then
        # Convertir le fichier docx en markdown temporaire
        pandoc "$FILE" -t markdown -o "$TEMP_FILE"

        # Nettoyer les balises indésirables
        sed -i'' -e 's/{.underline}//g' "$TEMP_FILE"
        sed -i'' -e 's/<!-- -->//g' "$TEMP_FILE"
        sed -i'' -e 's/\*\*//g' "$TEMP_FILE"
        sed -i'' -e 's/{width="[^"]*" height="[^"]*"//g' "$TEMP_FILE"

        # Ajouter un lien de retour au sommaire après chaque section
        echo "[Retour au sommaire](#table-of-contents)" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        cat "$TEMP_FILE" >> "$OUTPUT_FILE"
        echo -e "\n\n" >> "$OUTPUT_FILE"  # Ajoutez des nouvelles lignes entre les fichiers
    fi
done

# Ajouter un lien vers le sommaire après chaque titre de niveau 1
sed -i'' -e 's/^# \(.*\)/# \1\n[Retour au sommaire](#table-of-contents)/g' "$OUTPUT_FILE"

# Ajouter le sommaire
pandoc "$OUTPUT_FILE" -s --toc -o "$OUTPUT_FILE"

# Supprimez le fichier temporaire
rm "$TEMP_FILE"

echo "Conversion terminée. Le fichier Readme.md a été créé."
