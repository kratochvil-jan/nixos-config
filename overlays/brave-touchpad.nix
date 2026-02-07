self: super: {
  brave = super.brave.override {
    commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation --sync-url=\"http://192.168.88.13:8081/v2\"";
  };
}
