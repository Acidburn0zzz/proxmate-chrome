define [], () ->
  init = ->

  ###*
   * Parses a routing config and returns a usable joined proxy string
   * @param  {Object} config the config to use
   * @return {String}        the proxy string
  ###
  parseRoutingConfig = (config) ->
    configStrings = []
    # Parse startswith commands to shExpMatch(url, '*') expressions
    if config.startsWith.length > 0
      configStrings.push("shExpMatch(url, '#{config.startsWith}*')")

    # Parse contains commands to url.indexOf('multiple things') != -1 expressions
    if config.contains.length > 0
      for containElement in config.contains
        configStrings.push("url.indexOf('#{containElement}') != -1")

    # Parse host commands to host == 'x' expressions
    if config.host.length > 0
      configStrings.push("host == '#{config.host}'")

    return "(#{configStrings.join(' && ')})"

  ###*
   * Generates and scrumbles the available servers
   * @param  {Array} serverArray the array of servers to join
   * @return {String}             the serverString
  ###
  generateAndScrumbleServerString = (serverArray) ->
    for i in [serverArray.length-1..1]
        j = Math.floor Math.random() * (i + 1)
        [serverArray[i], serverArray[j]] = [serverArray[j], serverArray[i]]

    return "PROXY #{serverArray.join('; PROXY ')}"

  ###*
   * Generates a usable proxy autoconfig script based on provided servers and packages
   * @param  {Array} packages array out of package objects
   * @param  {Array} servers  array out of server objects
   * @return {String}         The usable script
  ###
  generateProxyAutoconfigScript = (packages, servers) ->
    countryServersMapping = {}
    # Transfer array into more usable object
    for server in servers
      # console.info server
      if server.country not of countryServersMapping
        countryServersMapping[server.country] = []

      countryServersMapping[server.country].push("#{server.url}:#{server.port}")

    parsedRules = {}
    # Iterate over all packages
    for pkg in packages
      # Try to find a proxy server based on the country
      if pkg.country of countryServersMapping
        if pkg.country not of parsedRules
          parsedRules[pkg.country] = []

        # Push all parsed routing elements into a object according to their mapped country
        for route in pkg.routing
          parsedRules[pkg.country].push(exports.parseRoutingConfig(route))

    # Parse all available information into if command blocks
    configLines = []
    i = 0
    for country, servers of countryServersMapping
      statement = 'else if'
      if i is 0
        statement = 'if'

      conditions = "#{parsedRules[country].join(' || ')}"
      configLines.push("#{statement} (#{conditions}) { return '#{exports.generateAndScrumbleServerString(servers)}' }")
      i += 1

    # Add the last else case, if no proxy was found
    configLines.push("else { return 'DIRECT'; }")

    return "function FindProxyForURL(url, host) {#{configLines.join(' ')}}"



  exports = {
    init: init
    generateProxyAutoconfigScript: generateProxyAutoconfigScript
    parseRoutingConfig: parseRoutingConfig
    generateAndScrumbleServerString: generateAndScrumbleServerString
  }

  return exports