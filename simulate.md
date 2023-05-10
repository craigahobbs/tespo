~~~ markdown-script
include 'powerwall.mds'


async function simulateMain()
    if vPowerwallScenario != null then
        simulateDetails()
        return
    endif

    simulateIndex()
endfunction


async function simulateIndex()
    # Set the title
    title = 'TESPO Simulations'
    setDocumentTitle(title)
    markdownPrint( \
        '[Home](#url=&var=)', \
        '', \
        '# ' + markdownEscape(title) \
    )

    # Fetch the scenarios
    vehicleScenarioURLs = fetch('scenarios/vehicleScenarios.json')
    powerwallScenarioURLs = fetch('scenarios/powerwallScenarioURLs.json')
    tespoRowsArray = arrayNew(0, 1, 2, 3, 6, 9, 12)

    # Run each powerwall scenario with each vehicle scenario
    scenarioData = arrayNew()
    foreach vehicleScenarioURL in vehicleScenarioURLs do
        foreach powerwallScenarioURL in powerwallScenarioURLs do
            isLoading = false
            foreach tespoRows in tespoRowsArray do
                # Get the cached scenario stats
                scenarioStats = simulateGetScenarioStats(vehicleScenarioURL, powerwallScenarioURL, tespoRows)
                if scenarioStats == null then
                    # Load each scenario
                    vehicleScenario = powerwallValidateVehicleScenario(fetch(vehicleScenarioURL))
                    powerwallScenario = powerwallLoadScenario(powerwallScenarioURL)

                    # Run the simulation
                    batteryPercent = powerwallBatteryPercent(powerwallScenario)
                    data = powerwallSimulate(powerwallScenario, batteryPercent, vehicleScenario, tespoRows)

                    # Compute the scenario URL
                    scenarioURL = "#var.vPowerwallScenario='" + encodeURIComponent(powerwallScenarioURL) + "'" + \
                        "&var.vVehicleScenario='" + encodeURIComponent(vehicleScenarioURL) + "'" + \
                        '&var.vTespoRows=' + tespoRows

                    # Compute the simulation statistics
                    scenarioStats = simulateStatistics(data)
                    objectSet(scenarioStats, 'Vehicle Scenario', objectGet(vehicleScenario, 'name'))
                    objectSet(scenarioStats, 'Powerwall Scenario', objectGet(powerwallScenario, 'name'))
                    objectSet(scenarioStats, 'Tespo Rows', '[' + tespoRows + '](' + scenarioURL + ')')

                    # Update the scenario cache
                    simulateSetScenarioStats(vehicleScenarioURL, powerwallScenarioURL, tespoRows, scenarioStats)
                    isLoading = true
                endif

                # Add the scenario table row
                arrayPush(scenarioData, scenarioStats)
            endforeach

            # If loading, render the loading message and set a timer to immediately continue
            if isLoading then
                markdownPrint('', 'Running simulations ' + arrayLength(scenarioData) + ' ...')
                setWindowTimeout(simulateIndex, 0)
                return
            endif
        endforeach
    endforeach

    # Render the scenario table
    dataTable(scenarioData, objectNew( \
        'categories', arrayNew('Vehicle Scenario', 'Powerwall Scenario', 'Tespo Rows'), \
        'fields', arrayNew('To Powerwall (kW)', 'From Powerwall (kW)', 'From Grid (kW)', 'To Grid (kW)'), \
        'markdown', arrayNew('Tespo Rows') \
    ))
endfunction


function simulateGetScenarioStats(vehicleScenarioURL, powerwallScenarioURL, tespoRows)
    scenarioDataStr = localStorageGet('ScenarioData')
    if scenarioDataStr != null then
        scenarioData = jsonParse(scenarioDataStr)
        scenarioKey = vehicleScenarioURL + ', ' + powerwallScenarioURL + ', ' + tespoRows
        return objectGet(scenarioData, scenarioKey)
    endif
    return null
endfunction


function simulateSetScenarioStats(vehicleScenarioURL, powerwallScenarioURL, tespoRows, scenarioStats)
    scenarioDataStr = localStorageGet('ScenarioData')
    if scenarioDataStr != null then
        scenarioData = jsonParse(scenarioDataStr)
    endif
    if scenarioData == null then
        scenarioData = objectNew()
    endif
    scenarioKey = vehicleScenarioURL + ', ' + powerwallScenarioURL + ', ' + tespoRows
    objectSet(scenarioData, scenarioKey, scenarioStats)
    localStorageSet('ScenarioData', jsonStringify(scenarioData))
endfunction


function simulateStatistics(data)
    # Add to/from powerwall/grid calculated fields
    dataCalculatedField( \
        data, \
        'To Powerwall (kW)', \
        'if([' + powerwallFieldPowerwall + '] < 0, [' + powerwallFieldPowerwall + '], 0)'  \
    )
    dataCalculatedField( \
        data, \
        'From Powerwall (kW)', \
        'if([' + powerwallFieldPowerwall + '] > 0, [' + powerwallFieldPowerwall + '], 0)' \
    )
    dataCalculatedField( \
        data, \
        'To Grid (kW)', \
        'if([' + powerwallFieldGrid + '] < 0, [' + powerwallFieldGrid + '], 0)' \
    )
    dataCalculatedField( \
        data, \
        'From Grid (kW)', \
        'if([' + powerwallFieldGrid + '] > 0, [' + powerwallFieldGrid + '], 0)' \
    )

    # Aggregate the data
    aggData = dataAggregate(data, objectNew( \
        'measures', arrayNew( \
            objectNew('field', powerwallFieldHome, 'function', 'sum'), \
            objectNew('field', powerwallFieldSolar, 'function', 'sum'), \
            objectNew('field', 'To Powerwall (kW)', 'function', 'sum'), \
            objectNew('field', 'From Powerwall (kW)', 'function', 'sum'), \
            objectNew('field', 'From Grid (kW)', 'function', 'sum'), \
            objectNew('field', 'To Grid (kW)', 'function', 'sum') \
        ) \
    ))

    # Compute self-powered percentage
    dataCalculatedField( \
        aggData, \
        'Self-Powered (%)', \
        '100 * ([' + powerwallFieldHome + '] - [From Grid (kW)]) / [' + powerwallFieldHome + ']' \
    )

    return arrayGet(aggData, 0)
endfunction


async function simulateDetails()
    powerwallScenario = powerwallLoadScenario(vPowerwallScenario)
    vehicleScenario = if(vVehicleScenario != null, powerwallValidateVehicleScenario(fetch(vVehicleScenario)), null)
    tespoRows = if(vTespoRows != null, vTespoRows, 0)

    initialBatteryPercent = powerwallBatteryPercent(powerwallScenario)
    data = powerwallSimulate(powerwallScenario, initialBatteryPercent, vehicleScenario, tespoRows)

    chartWidth = 1200
    chartHeight = 300

    markdownPrint( \
        '[Back](#var=)', \
        '', \
        '**Powerwall Scenario:** ' + markdownEscape(objectGet(powerwallScenario, 'name')) + ' \\', \
        '**Vehicle Scenario:** ' + markdownEscape(objectGet(vehicleScenario, 'name')) + ' \\', \
        '**TESPO Rows:** ' + tespoRows \
    )

    dataLineChart(data, objectNew( \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldBatteryPercent, powerwallFieldBackupPercent, 'Vehicle ID-1 Battery (%)', 'Vehicle ID-1 Charging Limit (%)'), \
        'yTicks', objectNew('start', 0, 'end', 100) \
    ))

    dataTable(data, objectNew( \
        'fields', arrayNew( \
            powerwallFieldDate, \
            powerwallFieldHome, \
            powerwallFieldSolar, \
            powerwallFieldGrid, \
            powerwallFieldPowerwall, \
            powerwallFieldBatteryPercent, \
            powerwallFieldBackupPercent, \
            'Vehicle ID-1 Connected', \
            'Vehicle ID-1 (kWh)', \
            'Vehicle ID-1 Battery (%)', \
            'Vehicle ID-1 Charging Rate (amps)', \
            'Vehicle ID-1 Charging Limit (%)' \
        ) \
    ))
endfunction


simulateMain()
~~~
