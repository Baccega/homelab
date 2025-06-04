{ config, pkgs, username, ... }:
{   
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
                    set_color --bold
                    echo "Starting up Fish shell 🐟"
                    set_color normal
                '';
            };
        };
    };

    # Make bash use fish on startup
    programs.bash = {
        interactiveShellInit = ''
            if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
            then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
            fi
        '';
    };
}