#! /usr/bin/env bash

for theme in '' '-blue' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-grey'; do
  for type in '' '-nord'; do
    case "$theme" in
      '')
        theme_color='#0860F2'
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
      rm -rf "theme${theme}${type}"
      cp -rf "theme" "theme${theme}${type}"
      sed -i "s/#0860f2/${theme_color}/g" "theme${theme}${type}"/*.svg
    elif [[ "$theme" != '' ]]; then
      rm -rf "theme${theme}"
      cp -rf "theme" "theme${theme}"
      sed -i "s/#0860f2/${theme_color}/g" "theme${theme}"/*.svg
    fi
  done
done

echo -e "DONE!"
