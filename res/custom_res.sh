#!/bin/bash

app_name0=$1
app_name=$2

sed -i 's/..\\/res\\/scalable.svg/..\\/res\\/128x128@2x.png/g' flatpak/rustdesk.json
sed -i 's/*.desktop",/*.desktop","install -Dm644 128x128@2x.png \\/app\\/share\\/icons\\/hicolor\\/256x256\\/apps\\/com.rustdesk.RustDesk.png"/g' flatpak/rustdesk.json
for p in res appimage flatpak; do
    find $p -type f -exec sed -i '/rustdesk.svg/d' {{}} \\;
    find $p -type f -exec sed -i '/scalable.svg/d' {{}} \\;
    find $p -type f -exec sed -i 's/RustDesk/{app_name0}/g' {{}} \\;
    find $p -type f -exec sed -i 's/rustdesk/{app_name}/g' {{}} \\;
done
mv res/rustdesk.service res/{app_name}.service
mv res/rustdesk.desktop res/{app_name}.desktop
mv res/rustdesk-link.desktop res/{app_name}-link.desktop