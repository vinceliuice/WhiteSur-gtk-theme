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
         base_color='#1e2229'
         text_color='#d9dce3'
         bg_color='#2b303b'
         tooltip_bg_color='#222730'
         insensitive_fg_color='#495265'
         dark_sidebar_bg='#323844'
      else
         base_color='#fbfcfd'
         text_color='#2d333e'
         bg_color='#f3f4f6'
         tooltip_bg_color='#f9fafb'
         insensitive_fg_color='#6a7792'
         dark_sidebar_bg='#f6f7f8'
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
      rm -rf "gtkrc${color}${theme}${type}"
      cp -rf "gtkrc${color}" "gtkrc${color}${theme}${type}"
      sed -i "s/#0860f2/${theme_color}/g" "gtkrc${color}${theme}${type}"
      if [[ "$color" == '-dark' ]]; then
        sed -i "s/#242424/${base_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#dedede/${text_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#333333/${bg_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#2a2a2a/${tooltip_bg_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#565656/${insensitive_fg_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#3b3b3b/${dark_sidebar_bg}/g" "gtkrc${color}${theme}${type}"
      else
        sed -i "s/#ffffff/${base_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#363636/${text_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#f5f5f5/${bg_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#fafafa/${tooltip_bg_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#7e7e7e/${insensitive_fg_color}/g" "gtkrc${color}${theme}${type}"
        sed -i "s/#f7f7f7/${dark_sidebar_bg}/g" "gtkrc${color}${theme}${type}"
      fi
    elif [[ "$theme" != '' ]]; then
      rm -rf "gtkrc${color}${theme}"
      cp -rf "gtkrc${color}" "gtkrc${color}${theme}"
      sed -i "s/#0860f2/${theme_color}/g" "gtkrc${color}${theme}"
    fi
  done
done
done

echo -e "DONE!"
