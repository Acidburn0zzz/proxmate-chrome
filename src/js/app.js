// Generated by CoffeeScript 1.7.1
(function() {
  require.config({
    paths: {
      "text": "../../bower_components/requirejs-text/text",
      "jquery": "../../bower_components/jquery/jquery"
    }
  });

  (function() {
    return require(['config', 'package-manager', 'storage', 'proxy-manager'], function(Config, PackageManager, Storage, ProxyManager) {
      Config.init();
      return Storage.init(function() {
        var pac, packages;
        PackageManager.init();
        ProxyManager.init();
        packages = PackageManager.getInstalledPackages();
        console.info(packages);
        return pac = ProxyManager.generateProxyAutoconfigScript(packages);
      });
    });
  })();

}).call(this);
