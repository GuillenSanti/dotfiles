# Define the prompt color and text format
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"

# Enable command substitution in the prompt
setopt prompt_subst

# Performance optimization: Cache git status
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'

# Function to format the current directory
format_pwd() {
  local pwd=$PWD
  if [[ "$pwd" == "$HOME" ]]; then
    # If the current directory is the home directory, display ~
    echo -n "%{$fg[cyan]%}~%{$reset_color%}"
  else
    # Replace the home directory with ~
    pwd="~${pwd#$HOME}"
    echo -n "%{$fg[cyan]%}${pwd}%{$reset_color%}"
  fi
}

# Optimized git prompt function that looks exactly like the original
git_prompt_info_fast() {
  # Only check if we're in a git repository (fast check)
  if [[ -n $(git rev-parse --git-dir 2>/dev/null) ]]; then
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n $branch ]]; then
      # Check if working directory is dirty (optimized)
      local git_status
      if git diff --quiet --ignore-submodules >/dev/null 2>&1; then
        git_status="%{$fg[green]%}✔ "
      else
        git_status="%{$fg[yellow]%}✗ "
      fi
      
      # Return the same format as the original git_prompt_info (sin 'git:')
      echo -n "%{$fg_bold[blue]%}[%{$fg[red]%}${branch}%{$fg[blue]%}] ${git_status}%{$reset_color%}"
    fi
  fi
}

# Redefine the prompt to use the optimized git function
PROMPT='%{$fg_bold[green]%}➜ %{$reset_color%}$(format_pwd) $(git_prompt_info_fast)%{$reset_color%}'

# Configure prefix and suffix for Git status (fallback)
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%})%{$fg[yellow]%}\u2718 "
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})%{$fg[green]%}✔ "
