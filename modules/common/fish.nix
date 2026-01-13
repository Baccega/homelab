{ config, pkgs, username, ... }:
{   
    programs.fish.enable = true;

    environment.systemPackages = with pkgs; map lib.lowPrio [
        bat
        lsd
    ];

    home-manager.users.${username} = {
        programs.fish = {
            enable = true;
            shellAliases = {
                ls = "lsd";
                ll = "lsd -lh";
                la = "lsd -lah";
                cat = "bat";
                gs = "git status";
                ga = "git commit --amend";
                gc = "git checkout";
            };

            functions = {
                # pnpm override
                pnpm = ''
                    if test "$argv[1]" = "ci"
                        command pnpm install --frozen-lockfile
                    else
                        command pnpm $argv
                    end
                '';

                # cd override to auto-activate conda/nvm
                # cd = ''
                #     builtin cd $argv
                #     if test -f .conda_environment
                #         useLocalCondaEnvironment
                #     end
                #     if test -f .nvmrc
                #         useLocalNodeEnvironment
                #     end
                # '';

                # sudo !!
                sudo = ''
                    if test "$argv" = "!!"
                        eval command sudo $history[1]
                    else
                        command sudo $argv
                    end
                '';

                # fish_greeting override
                fish_greeting = ''
                    if status is-interactive
                        set_color --bold
                        echo "Starting up Fish shell 🐟"
                        set_color normal
                    end
                '';
                
                __fish_command_not_found_handler = ''
                    echo "❌ Command not found:"(set_color purple) $argv
                    echo (set_color cyan)"🔎 Try '(set_color yellow)nix search $argv(set_color cyan)' or check your spelling."
                    return 127
                '';
            };
        };
    };

    # Make bash use fish on startup (only for interactive shells)
    programs.bash = {
        interactiveShellInit = ''
            # Only exec fish if:
            # 1. We're not already in fish
            # 2. This is an interactive shell (stdin is a TTY)
            # 3. No command was passed (BASH_EXECUTION_STRING is empty)
            if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && \
                  -z ''${BASH_EXECUTION_STRING} && \
                  -t 0 ]]
            then
                shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
                exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
            fi
        '';
    };
}