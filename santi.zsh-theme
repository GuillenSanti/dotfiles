# Define the prompt color and text format
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"

# Enable command substitution in the prompt
setopt prompt_subst

# Function to format the current directory
format_pwd() {
  local pwd=$PWD
  if [[ "$pwd" == "$HOME" ]]; then
    # If the current directory is the home directory, display ~
    echo -n "%{$fg[cyan]%}~%{$reset_color%}"
  else
    # Replace the home directory with ~
    pwd="~${pwd#$HOME}"

    # Extract the last folder
    local dir="${pwd##*/}"
    local parent="${pwd%/*}"
    echo -n "%{$fg[cyan]%}${parent}/%{$fg_bold[cyan]%}${dir}%{$reset_color%}"
  fi
}

# Redefine the prompt to use the format_pwd function and add Git status
PROMPT='%{$fg_bold[green]%}➜ %{$reset_color%}$(format_pwd) $(git_prompt_info)%{$reset_color%}'

# Configure prefix and suffix for Git status
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%})%{$fg[yellow]%}\u2718 "
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})%{$fg[green]%}✔ "

