{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.uhub;

  uhubPkg = pkgs.uhub.override { tlsSupport = cfg.tls; };

  pluginConfig = ""
    + optionalString cfg.plugins.authSqlite.enable ''
      plugin ${uhubPkg.mod_auth_sqlite}/mod_auth_sqlite.so "file=${cfg.plugins.authSqlite.file}"
    ''
    + optionalString cfg.plugins.logging.enable ''
      plugin ${uhubPkg.mod_logging}/mod_logging.so ${if cfg.plugins.logging.syslog then "syslog=true" else "file=${cfg.plugins.logging.file}"}
    ''
    + optionalString cfg.plugins.welcome.enable ''
      plugin ${uhubPkg.mod_welcome}/mod_welcome.so "motd=${pkgs.writeText "motd.txt"  cfg.plugins.welcome.motd} rules=${pkgs.writeText "rules.txt" cfg.plugins.welcome.rules}"
    ''
    + optionalString cfg.plugins.history.enable ''
      plugin ${uhubPkg.mod_chat_history}/mod_chat_history.so "history_max=${toString cfg.plugins.history.max} history_default=${toString cfg.plugins.history.default} history_connect=${toString cfg.plugins.history.connect}"
    ''
  ;

  uhubConfigFile = pkgs.writeText "uhub.conf" ''
    file_acl=${pkgs.writeText "users.conf" cfg.aclConfig}
    file_plugins=${pkgs.writeText "plugins.conf" pluginConfig}
    server_bind_addr=${cfg.address}
    server_port=${toString cfg.port}
    ${lib.optionalString cfg.enableTLS "tls_enable=yes"}
    ${cfg/gcc-5/.hubConfig}

    # Plugins
    ${if cfg.plugins.auth then
        ${if cfg.plugins.auth.sqlite then
            "plugin ${pkgs.uhub}/lib/uhub/mod_auth_sqlite.so \"file=${cfg.name}.users\""
          else
            "plugin ${pkgs.uhub}/lib/uhub/mod_auth_simple.so \"file=${cfg.name}.users.db\""}
      else null}
    ${if cfg.plugins.motd then
        "plugin ${pkgs.uhub}/lib/uhub/mod_welcome.so \"motd=${cfg.name}.motd rules=${cfg.name}.motd.rules\""
      else null}
    ${if cfg.plugins.welcome then
      else null}
    ${if cfg.plugins.history then
        "plugin ${cfg.uhub}/lib/mod_chat_history.so \"history_max_number history_default\""
      else null}
    ${if cfg.plugins.logging then
        "plugin ${pkgs.uhub}/lib/uhub/mod_logging.so \"filename=${cfg.name}.log\""
      else null}
  '';
in

{
  options = {

    services.uhub = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable uhub ADC hub.";
      };

      hubName = mkOption {
        type = types.string;
        default = "uhub";
        description = "uhub";
      };

      hubDescription = mkOption {
        type = types.string;
        default = "uhub";
        description = "uhub on NixOS";
      };

      port = mkOption {
        type = types.int;
        default = 1511;
        description = "TCP port to bind the hub to.";
      };

      address = mkOption {
        type = types.string;
        default = "any";
        description = "Address to bind the hub to.";
      };

      tls = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable TLS support.";
      };

      users = mkOption {
        type = types.int;
        default = 150;
        description = "";
      };

      plugins = {

        userAuth = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Authenticate users against database";
          };
          file = mkOption {
            type = types.string;
            example = "/var/db/uhub-users";
            description = "Path to user database. Use the uhub-passwd utility to create the database and add/remove users.";
          };
          sqlite = mkOption {
            type = types.bool;
            default = true;
            description = "Use sqlite database instead of a flat-file";
          };
        };

        logging = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to enable the logging plugin.";
          };
          file = mkOption {
            type = types.string;
            default = "";
            description = "Path of log file.";
          };
          syslog = mkOption {
            type = types.bool;
            default = false;
            description = "If true then the system log is used instead of writing to file.";
          };
        };

        motd = {};

        topic = {};

        welcome = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to enable the welcome plugin.";
          };
          motd = mkOption {
            default = "";
            type = types.lines;
            description = ''
              Welcome message displayed to clients after connecting 
              and with the <literal>!motd</literal> command.
            '';
          };
          rules = mkOption {
            default = "";
            type = types.lines;
            description = ''
              Rules message, displayed to clients with the <literal>!rules</literal> command.
            '';
          };
        };

        chatHistory = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to enable the history plugin.";
          };
          max = mkOption {
            type = types.int;
            default = 200;
            description = "The maximum number of messages to keep in history";
          };
          default = mkOption {
            type = types.int;
            default = 10;
            description = "When !history is provided without arguments, then this default number of messages are returned.";
          };
          connect = mkOption {
            type = types.int;
            default = 5;
            description = "The number of chat history messages to send when users connect (0 = do not send any history).";
          };
        };

      };
    };

  };

  config = mkIf cfg.enable {

    users = {
      extraUsers = singleton {
        name = "uhub";
        uid = config.ids.uids.uhub;
      };
      extraGroups = singleton {
        name = "uhub";
        gid = config.ids.gids.uhub;
      };
    };

    systemd.services.uhub = {
      description = "High performance peer-to-peer hub for the ADC network";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "notify";
        ExecStart  = "${uhubPkg}/bin/uhub -c ${uhubConfigFile} -u uhub -g uhub -L";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };

}