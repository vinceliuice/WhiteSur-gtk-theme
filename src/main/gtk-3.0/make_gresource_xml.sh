#! /bin/bash

INDEX="../../assets/gtk-3.0/common-assets/assets.txt"
WINDEX="../../assets/gtk-3.0/windows-assets/assets.txt"

if [ -f gtk.gresource.xml ]; then
  rm -rf gtk.gresource.xml
fi

echo '<?xml version="1.0" encoding="UTF-8"?>' >> gtk.gresource.xml
echo "<gresources>" >> gtk.gresource.xml
echo '  <gresource prefix="/org/gnome/Mcata-theme">' >> gtk.gresource.xml

for i in `cat $INDEX`
do
  echo "    <file>assets/$i.png</file>" >> gtk.gresource.xml
  echo "    <file>assets/$i@2.png</file>" >> gtk.gresource.xml
done

for i in `cat $WINDEX`
do
  echo "    <file>windows-assets/$i.png</file>" >> gtk.gresource.xml
  echo "    <file>windows-assets/$i@2.png</file>" >> gtk.gresource.xml
  echo "    <file>windows-assets/$i-dark.png</file>" >> gtk.gresource.xml
  echo "    <file>windows-assets/$i-dark@2.png</file>" >> gtk.gresource.xml
done

echo "    <file>gtk.css</file>" >> gtk.gresource.xml
echo "    <file>gtk-dark.css</file>" >> gtk.gresource.xml

echo "  </gresource>" >> gtk.gresource.xml
echo "</gresources>" >> gtk.gresource.xml

exit 0
