define ['proxy-manager', 'text!../testdata/packages.json', 'text!../testdata/servers.json'], (ProxyManager, testPackages, testServers) ->
  testServers = JSON.parse(testServers)
  testPackages = JSON.parse(testPackages)

  describe 'Proxy Manager', ->
    describe 'Script generation', ->
      it 'should generate the correct routing script', ->
        testConfigs = [{
          "startsWith": "",
          "contains": [],
          "host": "google.co.uk"
        },
        {
          "startsWith": "",
          "contains": ['also contains', 'multiple things'],
          "host": "google.com"
        },
        {
          "startsWith": "startswith",
          "contains": ['contains'],
          "host": "google.com"
        }]

        testResults = [
          "(host == 'google.co.uk')",
          "(url.indexOf('also contains') != -1 && url.indexOf('multiple things') != -1 && host == 'google.com')",
          "(shExpMatch(url, 'startswith*') && url.indexOf('contains') != -1 && host == 'google.com')"
        ]

        i = 0
        while(i < testConfigs.length)
          assert.equal(testResults[i], ProxyManager.parseRoutingConfig(testConfigs[i]))
          i += 1

      it 'should generate the correct proxy autoconfig', ->
        parseRoutingConfigSpy = sinon.spy(ProxyManager, 'parseRoutingConfig')
        generateAndScrumbleServerStringStub = sinon.spy(ProxyManager, 'generateAndScrumbleServerString')


        actualConfig = ProxyManager.generateProxyAutoconfigScript(testPackages, testServers)
        routeAmounts = 0
        for pkg in testPackages
          routeAmounts += pkg.routing.length
          for packageRoute in pkg.routing
            assert.isTrue(parseRoutingConfigSpy.calledWith(packageRoute), 'called the config generator with the correct parameter')

        assert.equal(routeAmounts, parseRoutingConfigSpy.callCount)
        expectedConfig = "function FindProxyForURL(url, host) {if ((url.indexOf('vevo.com') != -1 && url.indexOf('vevo2.com') != -1) || (shExpMatch(url, 'http://www.beatsmusic.com*'))) { return 'PROXY http://einsvonzwei.de:8080; PROXY http://zweivonzwei.de:8080' } else if ((host == 'www.google.com') || (host == 'another.com')) { return 'PROXY http://anothercountry.de:8080' } else { return 'DIRECT'; }}"
        assert.equal(expectedConfig, actualConfig)

        # Count if the scrumbleServers got called the right amount of times
        serverCountries = {}
        for server in testServers
          serverCountries[server.country] = true

        assert.equal(Object.keys(serverCountries).length, generateAndScrumbleServerStringStub.callCount)
        parseRoutingConfigSpy.restore()
        generateAndScrumbleServerStringStub.restore()
