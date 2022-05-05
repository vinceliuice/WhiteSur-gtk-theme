#! /usr/bin/env bash

for theme in '' '-blue' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-grey'; do
  for type in '' '-nord'; do
    case "$theme" in
      '')
        theme_color='#0860f2'
        ;;
      -blue)
        theme_color='#2E7CF7'
        ;;
      -purple)
        theme_color='#9A57A3'
        ;;
      -pink)
        theme_color='#E55E9C'
        ;;
      -red)
        theme_color='#ED5F5D'
        ;;
      -orange)
        theme_color='#E9873A'
        ;;
      -yellow)
        theme_color='#F3BA4B'
        ;;
      -green)
        theme_color='#79B757'
        ;;
      -grey)
        theme_color='#8C8C8C'
        ;;
    esac

    if [[ "$type" == '-nord' ]]; then
      menu_light='#fbfcfd'
      menu_dark='#2b303b'

      case "$theme" in
        '')
          theme_color='#5271ad'
          ;;
        -blue)
          theme_color='#4c7bd9'
          ;;
        -purple)
          theme_color='#b57daa'
          ;;
        -pink)
          theme_color='#cd7092'
          ;;
        -red)
          theme_color='#c35b65'
          ;;
        -orange)
          theme_color='#d0846c'
          ;;
        -yellow)
          theme_color='#e4b558'
          ;;
        -green)
          theme_color='#82ac5d'
          ;;
        -grey)
          theme_color='#8999a9'
          ;;
      esac
    fi

    if [[ "$type" != '' ]]; then
      rm -rf "thumbnail${theme}${type}.svg"
      cp -rf "thumbnail.svg" "thumbnail${theme}${type}.svg"
      sed -i "s/#0860f2/${theme_color}/g" "thumbnail${theme}${type}.svg"
      sed -i "s/#ffffff/${menu_light}/g" "thumbnail${theme}${type}.svg"
      sed -i "s/#333333/${menu_dark}/g" "thumbnail${theme}${type}.svg"
      sed -i "s/thumbnail-light/thumbnail-light${theme}${type}/g" "thumbnail${theme}${type}.svg"
      sed -i "s/thumbnail-dark/thumbnail-dark${theme}${type}/g" "thumbnail${theme}${type}.svg"
    elif [[ "$theme" != '' ]]; then
      rm -rf "thumbnail${theme}.svg"
      cp -rf "thumbnail.svg" "thumbnail${theme}.svg"
      sed -i "s/#0860f2/${theme_color}/g" "thumbnail${theme}.svg"
      sed -i "s/thumbnail-light/thumbnail-light${theme}/g" "thumbnail${theme}.svg"
      sed -i "s/thumbnail-dark/thumbnail-dark${theme}/g" "thumbnail${theme}.svg"
    fi
  done
done

echo -e "DONE!"
