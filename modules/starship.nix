{ config, pkgs, username, hostname_format, ... }:
{   
    home-manager.users.${username} = {
        programs.starship = {
            enable = true;
            settings = {
                add_newline = true;
                command_timeout = 10000;
                format = ''
                    $username$hostname$directory$fill$git_branch$git_state$git_status
                    $character
                '';
                right_format = ''
                    $cmd_duration
                '';
                git_branch = {
                    format = "[$symbol$branch(:$remote_branch)]($style) ";
                };
                git_status = {
                    conflicted = "⚔️";
                    ahead = "🏎💨";
                    behind = "😰";
                    diverged = "😵‍💫";
                    up_to_date = "✓";
                    untracked = "👻";
                    stashed = "📦";
                    modified = "📝";
                    staged = "[++\($count\)](green)";
                    renamed = "✏️";
                    deleted = "🗑";
                };
                hostname = {
                    format = hostname_format;
                };
                username = {
                    format = "[$user]($style)";
                };
                cmd_duration = {
                    min_time = 500;
                    format = "⏳ [$duration](bold yellow)";
                };
                directory = {
                    style = "blue";
                    format = "[$path]($style)";
                    truncate_to_repo = false;
                    truncation_length = 30;
                };
                fill = {
                    symbol = " ";
                };
            };
        };
    };

    # Should be used with fish
    programs.fish = {
        shellInit = ''
            starship init fish | source
        '';
    };
}