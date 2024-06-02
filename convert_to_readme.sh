#!/bin/bash

# Vérifiez si pandoc, ImageMagick et wkhtmltoimage sont installés
if ! command -v pandoc &> /dev/null; then
    echo "pandoc n'est pas installé. Vous pouvez l'installer via Homebrew : brew install pandoc"
    exit
fi

if ! command -v convert &> /dev/null; then
    echo "ImageMagick n'est pas installé. Vous pouvez l'installer via Homebrew : brew install imagemagick"
    exit
fi

if ! command -v wkhtmltoimage &> /dev/null; then
    echo "wkhtmltoimage n'est pas installé. Vous pouvez l'installer via Homebrew : brew install wkhtmltopdf"
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
IMG_DIR="images"

# Supprimez le fichier de sortie s'il existe déjà
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# Créez le répertoire d'images s'il n'existe pas
mkdir -p "$IMG_DIR"

# En-tête du fichier Readme.md
echo "# Sommaire" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Parcourez et fusionnez tous les fichiers .docx en Readme.md
# Trier les fichiers par numéro dans le titre
for FILE in $(ls "$DIRECTORY"/*.docx | sort -V); do
    if [ -f "$FILE" ]; then
        # Obtenez le nom du fichier sans extension
        FILENAME=$(basename "$FILE" .docx)
        
        # Convertir le fichier docx en markdown temporaire
        pandoc "$FILE" -t markdown -o "$TEMP_FILE"

        # Nettoyer les balises indésirables
        sed -i'' -e 's/{.underline}//g' "$TEMP_FILE"
        sed -i'' -e 's/<!-- -->//g' "$TEMP_FILE"
        sed -i'' -e 's/{width="[^"]*" height="[^"]*"//g' "$TEMP_FILE"
        sed -i'' -e 's/{=[a-z]*}//g' "$TEMP_FILE"

        # Extraire et convertir les tableaux en images
        grep -E '\|\s*(\|.*)*' "$TEMP_FILE" > temp_table.txt
        if [ -s temp_table.txt ]; then
            # Convertir les tableaux en HTML
            echo "<html><body><table>" > temp_table.html
            cat temp_table.txt >> temp_table.html
            echo "</table></body></html>" >> temp_table.html

            # Convertir le HTML en image
            IMG_FILE="$IMG_DIR/$FILENAME-table.png"
            wkhtmltoimage temp_table.html "$IMG_FILE"

            # Supprimer le tableau original du fichier markdown
            sed -i'' -e '/\|\s*(\|.*)*/d' "$TEMP_FILE"

            # Insérer l'image du tableau dans le fichier markdown
            echo "![Tableau $FILENAME]($IMG_FILE)" >> "$TEMP_FILE"
            echo -e "\n\n" >> "$TEMP_FILE"
        fi

        # Ajouter le titre du document original comme titre de niveau 1
        echo "# $FILENAME" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Ajouter le contenu nettoyé au fichier de sortie
        cat "$TEMP_FILE" >> "$OUTPUT_FILE"
        echo -e "\n\n" >> "$OUTPUT_FILE"  # Ajoutez des nouvelles lignes entre les fichiers
    fi
done

# Ajouter un lien vers le sommaire après chaque titre de niveau 1
sed -i'' -e 's/^# \(.*\)/# \1\n[Retour au sommaire](#sommaire)/g' "$OUTPUT_FILE"

# Ajouter le sommaire avec uniquement les titres de niveau 1
echo -e "\n# Sommaire\n" > temp_toc.md
grep '^# ' "$OUTPUT_FILE" | sed 's/^# //g' | sed 's/.*/- [&](#&)/g' >> temp_toc.md
cat temp_toc.md "$OUTPUT_FILE" > temp_with_toc.md
mv temp_with_toc.md "$OUTPUT_FILE"

# Supprimez les fichiers temporaires
rm "$TEMP_FILE" temp_toc.md temp_table.txt temp_table.html

echo "Conversion terminée. Le fichier Readme.md a été créé."
