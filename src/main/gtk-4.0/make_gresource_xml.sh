#! /bin/bash

INDEX="../../assets/gtk/common-assets/assets.txt"
SINDEX="../../assets/gtk/common-assets/sidebar-assets.txt"
WINDEX="../../assets/gtk/windows-assets/assets.txt"

if [ -f gtk.gresource.xml ]; then
  rm -rf gtk.gresource.xml
fi

echo '<?xml version="1.0" encoding="UTF-8"?>' >> gtk.gresource.xml
echo "<gresources>" >> gtk.gresource.xml
echo '  <gresource prefix="/org/gnome/theme">' >> gtk.gresource.xml

for i in `cat $INDEX`
do
  echo "    <file>assets/$i.png</file>" >> gtk.gresource.xml
  echo "    <file>assets/$i@2.png</file>" >> gtk.gresource.xml
done

for i in `cat $SINDEX`
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

echo "    <file>assets/scalable/checkbox-checked-symbolic.svg</file>" >> gtk.gresource.xml
echo "    <file>assets/scalable/checkbox-checked-big-symbolic.svg</file>" >> gtk.gresource.xml
echo "    <file>assets/scalable/checkbox-mixed-symbolic.svg</file>" >> gtk.gresource.xml
echo "    <file>assets/scalable/radio-checked-symbolic.svg</file>" >> gtk.gresource.xml
echo "    <file>assets/scalable/combobox-arrow-symbolic.svg</file>" >> gtk.gresource.xml
echo '    <file alias="assets/scalable/radio-mixed-symbolic.svg">assets/scalable/checkbox-mixed-symbolic.svg</file>' >> gtk.gresource.xml
echo "    <file>assets/scalable/checkbox-checked-symbolic@2.svg</file>" >> gtk.gresource.xml
echo "    <file>assets/scalable/checkbox-mixed-symbolic@2.svg</file>" >> gtk.gresource.xml
echo "    <file>assets/scalable/radio-checked-symbolic@2.svg</file>" >> gtk.gresource.xml
echo "    <file>assets/scalable/combobox-arrow-symbolic@2.svg</file>" >> gtk.gresource.xml
echo '    <file alias="assets/scalable/radio-mixed-symbolic@2.svg">assets/scalable/checkbox-mixed-symbolic@2.svg</file>' >> gtk.gresource.xml

echo "    <file>gtk.css</file>" >> gtk.gresource.xml
echo "    <file>gtk-dark.css</file>" >> gtk.gresource.xml

echo "  </gresource>" >> gtk.gresource.xml
echo "</gresources>" >> gtk.gresource.xml

exit 0
