alias config="code ~/.config" # Opens system config folder in VS Code
alias hypr="code ~/.config/hypr" # Opens Hyprland config folder in VS CODE
alias zshconfig='code $ZSH_CUSTOM && code ~/.zshrc'  # Opens ZSH config files in VS Code
alias source="source ~/.zshrc" # Changes source of shell to the path.
alias cl="clear" # Clear the terminal before this line. 
alias aliases="code $ZSH_CUSTOM/aliases.zsh" # Opens the file cotaining user defined aliases in VS-Code 
alias up='hyde-shell systemupdate up' # Opens system update
alias scripts='code $HOME/.local/lib/hyde/'

# System
# # Helpful aliases
alias c='clear'                                                        # clear terminal
alias l='eza -lh --icons=auto'                                         # long list
alias ls='eza -1 --icons=auto'                                         # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto'                                       # long list dirs
alias lt='eza --icons=auto --tree'                                     # list folder as tree
alias un='$aurhelper -Rns'                                             # uninstall package
# alias up='$aurhelper -Syu'                                             # update system/package/aur
alias pl='$aurhelper -Qs'                                              # list installed package
alias pa='$aurhelper -Ss'                                              # list available package
alias pc='$aurhelper -Sc'                                              # remove unused cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'                        # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
alias vc='code'                                                        # gui code editor
alias fastfetch='fastfetch --logo-type kitty'

# # Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
alias mkdir='mkdir -p'

## Theme folder (Temporary)
alias theme='code ~/.config/hyde/themes/'