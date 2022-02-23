#! /usr/bin/env bash

for color in '-light' '-dark'; do
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
      if [[ "$color" == '-dark' ]]; then
        bg_color='#2b303b'
        base_color='#1e222a'
      else
        bg_color='#f3f4f6'
        base_color='#fbfcfd'
      fi
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
      rm -rf "assets${color}${theme}${type}.svg"
      cp -rf "assets${color}.svg" "assets${color}${theme}${type}.svg"
      sed -i "s/#0860F2/${theme_color}/g" "assets${color}${theme}${type}.svg"
      if [[ "$color" == '-dark' ]]; then
        sed -i "s/#333333/${bg_color}/g" "assets${color}${theme}${type}.svg"
        sed -i "s/#242424/${base_color}/g" "assets${color}${theme}${type}.svg"
      else
        sed -i "s/#f5f5f5/${bg_color}/g" "assets${color}${theme}${type}.svg"
        sed -i "s/#ffffff/${base_color}/g" "assets${color}${theme}${type}.svg"
      fi
    elif [[ "$theme" != '' ]]; then
      rm -rf "assets${color}${theme}.svg"
      cp -rf "assets${color}.svg" "assets${color}${theme}.svg"
      sed -i "s/#0860F2/${theme_color}/g" "assets${color}${theme}.svg"
    fi
  done
done
done

echo -e "DONE!"
