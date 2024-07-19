# Define el color del prompt y el formato del texto
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"

# Habilitar sustitución de comandos en el prompt
setopt prompt_subst

# Función para formatear el directorio actual
format_pwd() {
  local pwd=$PWD
  if [[ "$pwd" == "$HOME" ]]; then
    # Si el directorio actual es el directorio principal, muestra ~
    echo -n "%{$fg[cyan]%}~%{$reset_color%}"
  else
    # Reemplaza el directorio principal por ~
    pwd="~${pwd#$HOME}"

    # Extrae la última carpeta
    local dir="${pwd##*/}"
    local parent="${pwd%/*}"
    echo -n "%{$fg[cyan]%}${parent}/%{$fg_bold[cyan]%}${dir}%{$reset_color%}"
  fi
}

# Redefinir el prompt para usar la función format_pwd y añadir estado de Git
PROMPT='%{$fg_bold[green]%}➜ %{$reset_color%}$(format_pwd) $(git_prompt_info)%{$reset_color%} '

# Configurar prefijo y sufijo del estado de Git
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}\u2718"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%}) %{$fg[green]%}✔"
