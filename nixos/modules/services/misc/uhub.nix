{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.uhub;

  uhubConfigFile = pkgs.writeText "uhub.conf" ''
    hubname=${cfg.name}
    hub_description=${cfg.description}
    server_bind_addr=${cfg.address}
    server_port=${toString cfg.port}
    file_acl=${pkgs.writeText "users.conf" cfg.aclConfig}
    file_plugins=${pkgs.writeText "plugins.conf" pluginConfig}
    tls_enable=${
      if cfg.tls.enable then
        "yes"
      else
        "no"
    } ${
      if cfg.tls.enable then
        "tls_require=yes
        tls_private_key=${cfg.tls.privatekey}
        tls_certificate=${cfg.tls.cert}"
      else null
    }
    ${cfg/gcc-5/.hubConfig}
  '';

  uhubPluginsConfigFile = pkgs.writeText "plugins.conf" ''
    # Plugins
    plugin ${pkgs.uhub}/lib/plugins/mod_auth_sqlite.so "file=${cfg.database}"
    ${
      if cfg.plugins.welcome.enable then
        "plugin ${pkgs.uhub}/lib/plugins/mod_welcome.so \
          \"motd=${cfg.plugins.welcome.motd} \
          rules=${cfg.plugins.welcome.rules}\""
      else
        null
    } ${
      if cfg.plugins.history then
        "plugin ${pkgs.uhub}/lib/plugins/mod_chat_history.so \
        \"file=${cfg.database} \
          history_max=${toString cfg.plugins.chathistory.max} \
          history_default=${toString cfg.plugins.chathistory.default} \
          history_connect=${toString cfg.plugins.chathistory.connect}\""
      else
        null
    } ${
      if cfg.plugins.logging then
        "plugin ${pkgs.uhub}/lib/plugins/mod_logging.so \
          \"filename=${cfg.plugins.logging}\""
      plugin ${uhubPlugin}/mod_logging.so ${if cfg.plugins.logging.syslog then "syslog=true" else "file=${cfg.plugins.logging.file}"}
      else
        null
    }
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

      name = mkOption {
        type = types.string;
        default = "uhub";
        description = "The name of your hub";
      };

      description = mkOption {
        type = types.string;
        default = "Uhub on NixOS";
        description = "The description of your hub";
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

      database = mkOption {
        type = types.string;
        default = "/var/db/uhub.db";
        description = "Path to sqlite database. Use the uhub-passwd utility to create the database and add/remove users.";
      };

      users = mkOption {
        type = types.int;
        default = 150;
        description = "Max limit for users allowed on the hub";
      };

      tls = mkOption {
        type = types.bool;
        default = false;
        description = "Enable TLS/SSL support";
      };

      plugin = {

        logging = {
          enable = mkOption {
            type = types.bool;
            default = true;
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

        welcome = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to enable the welcome plugin.";
          };
          motd = mkOption {
            type = types.lines;
            default = "Welcome to Uhub on NixOS";
            description = ''
              Welcome message displayed to clients after connecting 
              and with the <literal>!motd</literal> command.
            '';
          };
          rules = mkOption {
            type = types.lines;
            default = "";
            description = "Rules message, displayed to clients with the <literal>!rules</literal> command.";
          };
        };

        chathistory = {
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
            description = "When <literal>!history</literal> is provided without arguments, then this default number of messages are returned.";
          };
          connect = mkOption {
            type = types.int;
            default = 20;
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
      description = "High performance ADC (DC++) hub for peer-to-peer networks";
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