define 'ChromeProxyMock', ->
  return {
    proxy:
      settings:
        set: ->
        clear: ->
  }

require.config
  map:
    'proxy-manager':
      'chrome': 'ChromeProxyMock'

define ['proxy-manager', 'ChromeProxyMock','text!../testdata/packages.json', 'text!../testdata/servers.json'], (ProxyManager, Chrome, testPackages, testServers) ->
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
        # We remove the random element and directly join the string, to be able to compare the result
        generateAndScrumbleServerStringStub = sinon.stub(ProxyManager, 'generateAndScrumbleServerString', (serverArray) ->
          return "PROXY #{serverArray.join('; PROXY ')}"
        )

        # Check if the routing generator got called for every server routing element available
        actualConfig = ProxyManager.generateProxyAutoconfigScript(testPackages, testServers)
        routeAmounts = 0
        for pkg in testPackages
          routeAmounts += pkg.routing.length
          for packageRoute in pkg.routing
            assert.isTrue(parseRoutingConfigSpy.calledWith(packageRoute), 'called the config generator with the correct parameter')

        assert.equal(routeAmounts, parseRoutingConfigSpy.callCount)

        # Compare the pac script result
        expectedConfig = "function FindProxyForURL(url, host) {if ((url.indexOf('vevo.com') != -1 && url.indexOf('vevo2.com') != -1) || (shExpMatch(url, 'http://www.beatsmusic.com*'))) { return 'PROXY einsvonzwei.de:8080; PROXY zweivonzwei.de:8080' } else if ((host == 'www.google.com') || (host == 'another.com')) { return 'PROXY anothercountry.de:8080' } else { return 'DIRECT'; }}"
        assert.equal(expectedConfig, actualConfig)

        # Count if the scrumbleServers got called the right amount of times
        serverCountries = {}
        for server in testServers
          serverCountries[server.country] = true

        assert.equal(Object.keys(serverCountries).length, generateAndScrumbleServerStringStub.callCount)
        parseRoutingConfigSpy.restore()
        generateAndScrumbleServerStringStub.restore()

    describe 'Proxy setting / removing behaviour', ->
      it 'should set the proxy correctly', ->
        proxySetStub = sinon.stub(Chrome.proxy.settings, 'set')
        proxyString = 'asdf'

        expectedPayload =
          value:
            mode: "pac_script",
            pacScript:
              data: 'asdf',
          scope: 'regular'

        ProxyManager.setProxyAutoconfig(proxyString)

        assert.isTrue(proxySetStub.calledOnce)
        assert.isTrue(proxySetStub.calledWith(expectedPayload))

        proxyClearStub = sinon.stub(Chrome.proxy.settings, 'clear')
        ProxyManager.clearProxy()
        assert.isTrue(proxyClearStub.calledOnce)


