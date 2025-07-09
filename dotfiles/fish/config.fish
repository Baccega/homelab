# My Fish configuration (On MacOS)
# Author: Baccega Sandro

# --- Functions replacements

# Extra ls functions using exa
function ls
    lsd $argv
end

function ll
    ls -lh $argv
end

function la
    ls -lah $argv
end

# Using bat instead of cat
function cat
    bat $argv
end

function gs
    git status $argv
end

function ga
    git commit --amend $argv
end

function gc
    git checkout $argv
end

# Make pnpm ci work as expected
function pnpm
    if [ $argv[1] = "ci" ]
        command pnpm install --frozen-lockfile
    else
        command pnpm $argv
    end
end

# Change conda environment or nvm environment automatically if .conda_environment or .nvmrc is present
function cd
   builtin cd $argv
   if test -f .conda_environment
       useLocalCondaEnvironment
       end
    if test -f .nvmrc
       useLocalNodeEnvironment
       end
end

# Add sudo !! functionality to fish
function sudo
    if test "$argv" = !!
        eval command sudo $history[1]
    else
        command sudo $argv
        end
end

# Replace fish greeting
function fish_greeting
    set_color --bold
    echo "Starting up Fish shell 🐟"
    set_color normal
end

# Other functions

function useLocalCondaEnvironment
    conda activate (cat .conda_environment) 
    echo ""
    echo "Changing Conda environment to 🐍 [$(set_color --bold 0CED88; cat .conda_environment; set_color normal)]"
end

function useLocalNodeEnvironment
    nvm use
    echo ""
    echo "Changing NodeJS version to $(set_color --bold 0CED88) $(cat .nvmrc; set_color normal)"
    set_color normal
end

# --- Environment setup

# Add homebrew to PATH
set PATH /opt/homebrew/bin $PATH
# # Add maven to PATH
# set PATH ~/apache-maven-3.8.7/bin $PATH
export PATH

# # Set $JAVA_HOME
# # Check if the .java_environment file exists in the current directory
# if test -f .java_environment
#     # Read the content of the file
#     set java_env (cat .java_environment)

#     if test $java_env = "21"
#         # Find the latest version of OpenJDK 21
#         set -l jdk_version (find /opt/homebrew/Cellar/openjdk -type d -name '21.0.*' | awk -F'/' '{print $NF}')
#         set JAVA_HOME /opt/homebrew/Cellar/openjdk/$jdk_version/libexec/openjdk.jdk/Contents/Home
#     else if test $java_env = "17"
#         # Find the latest version of OpenJDK 17
#         set -l jdk_version (find /opt/homebrew/Cellar/openjdk@17 -type d -name '17.0.*' | awk -F'/' '{print $NF}')
#         set JAVA_HOME /opt/homebrew/Cellar/openjdk@17/$jdk_version/libexec/openjdk.jdk/Contents/Home
#     else if test $java_env = "11"
#         # Find the latest version of OpenJDK 11
#         set -l jdk_version (find /opt/homebrew/Cellar/openjdk@11 -type d -name '11.0.*' | awk -F'/' '{print $NF}')
#         set JAVA_HOME /opt/homebrew/Cellar/openjdk@11/$jdk_version/libexec/openjdk.jdk/Contents/Home
#     end
# else
#     # Fallback to JDK 17
#     set -l jdk_version (find /opt/homebrew/Cellar/openjdk@17 -type d -name '17.0.*' | awk -F'/' '{print $NF}')
#     set JAVA_HOME /opt/homebrew/Cellar/openjdk@17/$jdk_version/libexec/openjdk.jdk/Contents/Home
# end

# export JAVA_HOME

# # Set $MAVEN_HOME
# set MAVEN_HOME ~/apache-maven-3.8.7 $MAVEN_HOME
# export MAVEN_HOME

# Starship setup
starship init fish | source

nvm use lts

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# eval /opt/homebrew/anaconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<

# Change conda environment automatically if .conda_environment is present (on terminal startup)
if test -f .conda_environment
   useLocalCondaEnvironment
   end
if test -f .nvmrc
   useLocalNodeEnvironment
   end
   
# pnpm
# set -gx PNPM_HOME "/Users/sandrobaccega/Library/pnpm"
# if not string match -q -- $PNPM_HOME $PATH
#   set -gx PATH "$PNPM_HOME" $PATH
# end
# pnpm end
