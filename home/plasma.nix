{ inputs, pkgs, ... }:

let
  wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
in
{
  home.packages = with pkgs; [
    quota
  ];
  programs.plasma = {
    enable = true;

    overrideConfig = true;

    desktop = {
      # disable icons:
      # "~/.config/plasma-org.kde.plasma.desktop-appletsrc"
      # plugin=org.kde.desktopcontainment
    };

    workspace = {
      enableMiddleClickPaste = false;
      clickItemTo = "select";
      colorScheme = "BreezeLight";
      lookAndFeel = "org.kde.breezetwilight.desktop";
      cursor = {
        animationTime = 5;
        cursorFeedback = "Bouncing";
        theme = "Breeze Dark";
        taskManagerFeedback = true;
        size = 24;
      };
      iconTheme = "Breeze Dark";
      wallpaper = wallpaper;
    };

    hotkeys.commands."launch-konsole" = {
      name = "Launch Alacritty";
      key = "Alt+Return";
      command = "alacritty";
    };

    fonts = {
      general = {
        family = "JetBrains Mono";
        pointSize = 10;
      };
    };

    panels = [
      # Application name, Global menu and Song information and playback controls at the top
      {
        location = "bottom";
        height = 36;
        opacity = "opaque";
        hiding = "normalpanel";
        widgets = [
          {
            kickoff = {
              sortAlphabetically = true;
              icon = "nix-snowflake";
            };
          }
          {
            iconTasks = {
              iconsOnly = false;
              appearance = {
                highlightWindows = true;
                indicateAudioStreams = true;
                rows.multirowView = "never";
                iconSpacing = "small";
              };
            };
          }
          "org.kde.plasma.panelspacer"
          {
            plasmusicToolbar = {
              panelIcon = {
                albumCover = {
                  useAsIcon = false;
                  radius = 8;
                };
                icon = "view-media-track";
              };
              playbackSource = "auto";
              musicControls.showPlaybackControls = true;
              songText = {
                displayInSeparateLines = true;
                maximumWidth = 640;
                scrolling = {
                  behavior = "alwaysScroll";
                  speed = 3;
                };
              };
            };
          }
          # {
          #   pager = {
          #     general = {
          #       showOnlyCurrentScreen = true;
          #       displayedText = "desktopNumber";
          #       selectingCurrentVirtualDesktop = "showDesktop";
          #     };
          #   };
          # }
          {
            systemTray.items = {
              # We explicitly show bluetooth and battery
              shown = [
                "org.kde.plasma.volume"
                "org.kde.plasma.battery"
                "plugin=org.kde.plasma.clipboard"
                "plugin=org.kde.plasma.devicenotifier"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.keyboardlayout"
                "org.kde.plasma.keyboardindicator"
                "org.kde.kscreen"
                "org.kde.plasma.nightcolorcontrol"
                "plugin=org.kde.plasma.notifications"
              ];
              # And explicitly hide networkmanagement and volume
              hidden = [
              ];
            };
          }
          {
            digitalClock = {
              calendar.firstDayOfWeek = "monday";
              calendar.showWeekNumbers = true;
              time.format = "24h";
              time.showSeconds = "onlyInTooltip";
              date.format.custom = "dddd, dd MMMM";
              date.position = "besideTime";
            };
          }
        ];
      }
    ];

    # window-rules = [
    #   {
    #     description = "Dolphin";
    #     match = {
    #       window-class = {
    #         value = "dolphin";
    #         type = "substring";
    #       };
    #       window-types = [ "normal" ];
    #     };
    #     apply = {
    #       noborder = {
    #         value = true;
    #         apply = "force";
    #       };
    #       # `apply` defaults to "apply-initially"
    #       maximizehoriz = true;
    #       maximizevert = true;
    #     };
    #   }
    # ];

    powerdevil = {
      AC = {
        powerProfile = "performance";
        powerButtonAction = "sleep";
        whenLaptopLidClosed = "sleep";
        whenSleepingEnter = "standbyThenHibernate";
        # If enabled, the lid action will be inhibited when an external monitor is connected.
        inhibitLidActionWhenExternalMonitorConnected = false;
        autoSuspend = {
          action = "sleep";
          idleTimeout = 60 * 10;
        };
        turnOffDisplay = {
          idleTimeout = 60 * 7;
          idleTimeoutWhenLocked = "immediately";
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 60 * 5;
        };
        dimKeyboard.enable = true;
      };
      battery = {
        powerProfile = "balanced";
        powerButtonAction = "sleep";
        whenLaptopLidClosed = "sleep";
        whenSleepingEnter = "standbyThenHibernate";
        # If enabled, the lid action will be inhibited when an external monitor is connected.
        inhibitLidActionWhenExternalMonitorConnected = false;
        autoSuspend = {
          action = "sleep";
          idleTimeout = 60 * 10;
        };
        turnOffDisplay = {
          idleTimeout = 60 * 4;
          idleTimeoutWhenLocked = "immediately";
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 60 * 3;
        };
        dimKeyboard.enable = true;
      };
      lowBattery = {
        powerProfile = "powerSaving";
        powerButtonAction = "hibernate";
        whenLaptopLidClosed = "hibernate";
        inhibitLidActionWhenExternalMonitorConnected = false;
        autoSuspend = {
          action = "hibernate";
          idleTimeout = 60 * 5;
        };
        turnOffDisplay = {
          idleTimeout = 60 * 4;
          idleTimeoutWhenLocked = "immediately";
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 60 * 3;
        };
        dimKeyboard.enable = true;
      };
      batteryLevels = {
        criticalAction = "hibernate";
        criticalLevel = 5;
        lowLevel = 15;
      };
      general = {
        pausePlayersOnSuspend = true;
      };
    };

    kwin = {
      borderlessMaximizedWindows = true;
      edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
      cornerBarrier = false;

      # Tiling windows
      scripts.polonium = {
        # enable = true;
        enable = false;
        settings = {
          borderVisibility = "borderSelected";
        };
      };

      effects = {
        blur.enable = true;
        desktopSwitching.animation = "off";
        dimAdminMode.enable = true;
        magnifier.enable = false;
        minimization.animation = "off";
        shakeCursor.enable = true;
        slideBack.enable = false;
        translucency.enable = false;
        windowOpenClose.animation = "off";
        zoom.enable = false;
      };

      nightLight = {
        enable = true;
        mode = "automatic";
        temperature.day = 6500;
        temperature.night = 2600;
      };

      virtualDesktops = {
        number = 6;
        rows = 1;
        # rows = 3;
      };
    };

    kscreenlocker = {
      appearance = {
        alwaysShowClock = true;
        showMediaControls = false;
        wallpaper = wallpaper;
      };
      autoLock = true;
      passwordRequired = true;
      lockOnResume = true;
      timeout = 10; # minutes
    };

    session = {
      general.askForConfirmationOnLogout = true;
      sessionRestore.excludeApplications = [
        "alacritty"
      ];
      sessionRestore.restoreOpenApplicationsOnLogin = "onLastLogout";
    };

    shortcuts = {
      ksmserver."Lock Session" = "";

      kmix.decrease_volume = "Volume Down";
      kmix.increase_volume = "Volume Up";
      kmix.mic_mute = [
        "Microphone Mute"
        "Meta+Volume Mute"
      ];
      kmix.mute = "Volume Mute";
      kwin."Edit Tiles" = "Meta+T";

      kwin."Expose" = "Meta+,";
      # kwin.Expose = "Meta+\\";
      # kwin.ExposeAll = ["Ctrl+F10" "Launch (C)"];
      # kwin.ExposeClass = "Ctrl+F7";
      # kwin."Grid View" = "Meta+G";

      kwin."Window Close" = "Meta+q";
      kwin."Kill Window" = "Meta+Shift+q";
      kwin."Window Maximize" = "Meta+F";

      kwin.PoloniumInsertAbove = "Meta+Shift+K";
      kwin.PoloniumInsertBelow = "Meta+Shift+J";
      kwin.PoloniumInsertLeft = "Meta+Shift+H";
      kwin.PoloniumInsertRight = "Meta+Shift+L";
      kwin.PoloniumOpenSettings = "Meta+\\\\,none";
      kwin.PoloniumResizeAbove = "Meta+Ctrl+K";
      kwin.PoloniumResizeBelow = "Meta+Ctrl+J";
      kwin.PoloniumResizeLeft = "Meta+Ctrl+H";
      kwin.PoloniumResizeRight = "Meta+Ctrl+L";
      kwin.PoloniumRetileWindow = "Meta+Shift+Space";

      kwin."Switch Window Down" = "Meta+J";
      kwin."Switch Window Left" = "Meta+H";
      kwin."Switch Window Right" = "Meta+L";
      kwin."Switch Window Up" = "Meta+K";
      kwin."Switch to Desktop 1" = "Meta+`";
      kwin."Switch to Desktop 2" = "Meta+1";
      kwin."Switch to Desktop 3" = "Meta+2";
      kwin."Switch to Desktop 4" = "Meta+3";
      kwin."Switch to Desktop 5" = "Meta+4";
      kwin."Switch to Desktop 6" = "Meta+5";

      mediacontrol.mediavolumedown = [ ];
      mediacontrol.mediavolumeup = [ ];
      mediacontrol.nextmedia = "Media Next";
      mediacontrol.pausemedia = "Media Pause";
      mediacontrol.playmedia = [ ];
      mediacontrol.playpausemedia = "Media Play";
      mediacontrol.previousmedia = "Media Previous";
      mediacontrol.seekbackwardmedia = "Media Rewind";
      mediacontrol.seekbackwardmedialong = [ ];
      mediacontrol.seekforwardmedia = "Media Fast Forward";
      mediacontrol.seekforwardmedialong = [ ];
      mediacontrol.stopmedia = "Media Stop";

      org_kde_powerdevil."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness" = "Monitor Brightness Down";
      org_kde_powerdevil."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
      org_kde_powerdevil.Hibernate = "Hibernate";
      org_kde_powerdevil."Increase Keyboard Brightness" = "Keyboard Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness" = "Monitor Brightness Up";
      org_kde_powerdevil."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
      org_kde_powerdevil.PowerDown = "Power Down";
      org_kde_powerdevil.PowerOff = "Power Off";
      org_kde_powerdevil.Sleep = "Sleep";
      org_kde_powerdevil."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
      org_kde_powerdevil."Turn Off Screen" = [ ];
      org_kde_powerdevil.powerProfile = [
        "Battery"
        "Meta+B"
      ];

      # plasmashell."activate application launcher" = ["Meta" "Alt+F1"];
      plasmashell."activate application launcher" = [ "Meta" ];
      plasmashell.show-on-mouse-pos = "Meta+V";

      "services/Alacritty.desktop"._launch = [
        "Ctrl+Alt+T"
        "Alt+Return"
      ];

      "services/org.kde.spectacle.desktop".RectangularRegionScreenShot = [
        "Meta+Shift+Print"
        "Meta+Shift+S"
      ];
    };

    configFile = {
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;
      kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "SF";
      kwinrc.Desktops.Number = {
        # value = 8;
        # Forces kde to not change this value (even through the settings app).
        immutable = true;
      };
      kcminputrc.Keyboard.RepeatDelay = 300;
      kcminputrc.Keyboard.RepeatRate = 35;

      kcminputrc.Mouse.X11LibInputXAccelProfileFlat = true;
      kcminputrc.Mouse.XLbInptAccelProfileFlat = false;
      kcminputrc.Mouse.XLbInptPointerAcceleration = "-0.2";

      kdeglobals.General.TerminalApplication = "alacritty";
      kdeglobals.General.TerminalService = "Alacritty.desktop";

      kxkbrc.Layout.LayoutList = "us,cz";

      klipperrc.General.IgnoreImages = false;
      klipperrc.General.MaxClipItems = 10000;
      klipperrc.General.KeepClipboardContents = true;

    };
  };
}
